local configurationManager = require 'ConfigurationManager'
local Config = configurationManager.getConfig()

-- Lightroom API
local LrFileUtils = import 'LrFileUtils'
local LrPathUtils = import 'LrPathUtils'
local LrTasks =  import 'LrTasks'
local LrStringUtils = import 'LrStringUtils'
local LrDialogs = import 'LrDialogs'
local LrLogger = import 'LrLogger'
local LrApplication = import 'LrApplication'

-- "static imports"
local child = LrPathUtils.child
local exists = LrFileUtils.exists
local message = LrDialogs.message
local fileAttributes = LrFileUtils.fileAttributes

local catalog = import 'LrApplication'.activeCatalog()
local next = next
local logger = LrLogger 'importPhotoLogger'
logger:enable 'logfile'

local previouslyImported


if not exists(Config.input) then
    message("Missing work folder", 
        "The input folder (" .. Config.input .. ") seems to point to an unexisting location.", 
        "error")
    return
end

LrTasks.startAsyncTask(function()   
    
	debugInfo("startAsyncTask", Config.allowedCompanies)
	local jobFolder = acquireNextJob()
    
    if not jobFolder then
        message("No available jobs found",
            "There are no jobs at the moment which are both fully downloaded and not already being worked on. Try again later.",
            "info")
        return
    end
    
    logger:trace("Got lock on job folder " .. jobFolder .. " - proceeding to import.")
    
    catalog:triggerImportFromPathWithPreviousSettings(jobFolder)    
    
    logger:trace("Folder " .. jobFolder .. " was scheduled for import" )    
    
end)

function isPicture(filename)
    local ext = LrStringUtils.upper(LrPathUtils.extension(filename))
    return ext == "JPG" or ext == "JPEG"
end


function numberOfPicturesIn(path)
    local result = 0
    
    for file in LrFileUtils.files(path) do
        if isPicture(file) then
            result = result + 1
        end
    end
    
    return result
end

function boolStr(bool) if bool then return "true" else return "false" end end

function numberInFile(file)
    return tonumber(LrStringUtils.trimWhitespace(LrFileUtils.readFile(file)))
end

function debugInfo(area, msg)
    if Config.dbg then
        message("DEBUG: "..area, msg, "info")
    end
end

function isAllowedCompany(jobFolder)
	if next(Config.allowedCompanies) == nil  or  Config.charsReservedToCompanyPrefix < 1 then
		return true
	end
    local jobName = LrStringUtils.upper(LrPathUtils.leafName(jobFolder))
	local companyPrefix = string.sub(jobName, 1, Config.charsReservedToCompanyPrefix)
	return has_value(Config.allowedCompanies, companyPrefix)
end

function has_value (tab, val)
    for index, value in ipairs (tab) do
        if value == val then
            return true
        end
    end

    return false
end



function getJobPriority(jobFolder)
    local priorityFile = child(jobFolder, "priority.txt")
    
    if not exists(priorityFile) then
        debugInfo("getJobPriority", "priority.txt not found")
        return 0
    end
        
    return numberInFile(priorityFile)
end

function completelyTransferred(jobFolder)
    local totalFilesFile = child(jobFolder, "total_images.txt")
    
    if not exists(totalFilesFile) then
        debugInfo("completelyTransferred", "total_images.txt not found")
        return false
    end
    
    local actual = numberOfPicturesIn(jobFolder)    
    local expected = numberInFile(totalFilesFile)
    
    debugInfo("completelyTransferred",
        "actual="..actual.."\n"..
        "expected="..expected.."\n"..
        "equal="..boolStr(actual==expected))
    
    return actual == expected
end

function lockfile(jobFolder) return child(jobFolder, "lockfile") end
function locked(jobFolder) return exists(lockfile(jobFolder)) end

function writeFile(file, content)
    io.output(file)
    io.write(content)
    io.close()
end

function tryLock(jobFolder)
    if not locked(jobFolder) then
        writeFile(lockfile(jobFolder), Config.user)
        debugInfo("tryLock", "wrote lock file")
    else
        debugInfo("tryLock", "already locked")
    end
end

function lockedByMe(jobFolder)
    return locked(jobFolder) and LrFileUtils.readFile(lockfile(jobFolder)) == Config.user
end

-----------------------------------------------

warnNilDate = function(path) message(
        "Unable to read creation date", 
        "Creation date could not be determined for path='" 
        .. path 
        .. "'. Ignoring and trying to find a different one.", 
        "warning")
end

warnNilPath = function(path) message(
        "Nil path encountered", 
        "An nil path was passed to byCreationDateAscending",
        "warning")
end

dateIsInvalid = function(date, path)
    local invalid = not date
    if invalid then
        warnNilDate(path)
    end
    return invalid
end

pathIsInvalid = function(path)
    local invalid = not path
    if invalid then
        warnNilPath()
    end
    return invalid
end

-- Returns true if a is older than b. Both must be valid paths.
byCreationDateAscending = function(folderA, folderB)
	local pathA = folderA.folder
	local pathB = folderB.folder
	
    if pathIsInvalid(pathA) then return false end
    local creationDateA = fileAttributes(pathA).fileCreationDate
    if dateIsInvalid(creationDateA, pathA) then return false end

    if pathIsInvalid(pathB) then return true end
    local creationDateB = fileAttributes(pathB).fileCreationDate
    if dateIsInvalid(creationDateB, pathB) then return true end

	if folderA.priority ~= folderB.priority then
		return  folderA.priority > folderB.priority 
	end
	
    return creationDateA < creationDateB
end

-----------------------------------------------

function jobFolders()
    return LrFileUtils.directoryEntries(Config.input)
end

function jobFoldersByAge()
    local entries = {}
    
    for f in jobFolders() do
		local jobFolderWithPriority = {
			folder = f,
			priority = getJobPriority(f)
		}
	
        table.insert(entries, jobFolderWithPriority)
    end

    -- debugInfo("jobFoldersByAge", table.concat(entries, "\n"))
    
    table.sort(entries, byCreationDateAscending)
    
    return entries
end

function eligibleForImport(jobFolder)
    
    debugInfo("eligibleForImport",  
        "folder="..jobFolder.."\n"..
        "locked="..boolStr(locked(jobFolder)).."\n"..
        "completelyTransferred="..boolStr(completelyTransferred(jobFolder)).."\n"..
		"allowedCompanies="..boolStr(isAllowedCompany(jobFolder)))
				
    return not locked(jobFolder)
        and completelyTransferred(jobFolder)
		and isAllowedCompany(jobFolder)
end

-- Get the folder path to a ready job that is not locked
function acquireNextJob()

    -- find and lock oldest eligible job folder
    for _, jobFolder in ipairs(jobFoldersByAge()) do
        if eligibleForImport(jobFolder.folder) then
            tryLock(jobFolder.folder)
            
            if lockedByMe(jobFolder.folder) then
                return jobFolder.folder
            end
        end
    end
    
    return nil
end


function implode(list, s)
    return list
        and implode(list.tail, (s and s .. ", " or "") .. list.head) 
        or s 
end
