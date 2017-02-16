-- Main export script
require 'Config'

-- Lightroom API
local LrPathUtils = import 'LrPathUtils'
local LrFileUtils = import 'LrFileUtils'
local LrErrors = import 'LrErrors'
local LrDialogs = import 'LrDialogs'
local LrTasks = import 'LrTasks'
local LrLogger = import 'LrLogger'
local LrStringUtils = import 'LrStringUtils'
local LrApplication = import 'LrApplication'

-- "static imports"
local exists = LrFileUtils.exists
local leafName = LrPathUtils.leafName
local child = LrPathUtils.child
local copy = LrFileUtils.copy
local delete = LrFileUtils.delete
local files = LrFileUtils.files

local catalog =  LrApplication.activeCatalog()

local logger = LrLogger 'outputPhotoLogger'
logger:enable 'logfile'


ExportTask = {
	processRenderedPhotos = function( functionContext, exportContext )
	
		local inputFolder = inputFolder()
		local jobName = inputFolder:getName()
		local jobFolder = child(Config.input, jobName)
		local outputFolder = createOutputFolder(jobFolder)
	
		logger:trace("Starting to export " .. jobName.." with color space: " ..  exportContext.propertyTable["LR_export_colorSpace"] .. " to folder " .. jobFolder)
		local companyPrefix = string.sub(jobName, 1, 3)
		local companyExportSettings = Config.companyExportSettings[companyPrefix]				

		if Config.dbg then
		  -- see a list of all settings in the property table
		  for k, v in pairs( exportContext.propertyTable["< contents >"] ) do 
				logger:trace(k .. ': ' .. tostring(v) .. '\n')
		  end 
		end
		
		if not companyExportSettings then
			for k, v in pairs( companyExportSettings ) do 
					logger:trace("Export rule: " .. tostring(k) .. ' = ' .. tostring(v) .. '\n')
					local currentValue = tostring(exportContext.propertyTable[k])
					if currentValue ~= tostring(v) then
						logger:trace("" .. currentValue .. " is not legal setting for " .. k)	
						 error ("" .. currentValue .. " is not legal setting for " .. k .. ", since that should be " .. tostring(v))
					end
			 end 
		end
		
		if not outputFolder then
			error "Unable to create destination directory."
		end
	
		
		configureAndExport(exportContext, 
			exportContext.exportSession, 
			exportContext.propertyTable, 
			outputFolder,
			inputFolder,
			jobFolder
			)
	end
}

function createOutputFolder(jobFolder)
	local outputFolder = child(jobFolder, "output")
	
	local exists = exists(outputFolder)
		
	if not exists then 
		LrFileUtils.createDirectory(outputFolder)
	elseif exists == 'file' then
		error "Destination is a file."
	end
	
	return outputFolder
end	



-- Return nothing if successful, else return overwritten file
function copyPhoto(srcFilePath, outputFolder, rendition, jobFolder)
	
	local destFilePath = child(outputFolder, leafName(srcFilePath))	
	
	logger:trace("Orginal source should have been " .. child(jobFolder, leafName(srcFilePath)))
	if not exists(child(jobFolder, leafName(srcFilePath))) then
		error ("Exporting to wrong jobFolder " .. jobFolder .. "?")
	end 
	
	local overwrittenFile
	
	if exists(destFilePath) then
		delete(destFilePath)
		overwrittenFile = leafName(destFilePath)
	end
	
	local successCopy = copy(srcFilePath, destFilePath)
	markExportedPhotoLabelAsGreenColor(rendition)
	logger:trace("Copied from " .. srcFilePath .. " to " .. destFilePath)
	
	--delete lightroom virtual temp file
	delete(srcFilePath)
	return overwrittenFile
end

function markExportedPhotoLabelAsGreenColor(rendition)

	-- Concurrency hack
	while catalog.hasWriteAccess do
		LrTasks.yield();
	end
	
	catalog:withWriteAccessDo("markExported", function()
		rendition.photo:setRawMetadata("label", "green")
	end)
end


function getNumPhotosInFolder(folder)
	local sum = 0
	
	for file in files(folder) do
		local fileExtension = LrStringUtils.upper(LrPathUtils.extension(file))
		
		if fileExtension == 'JPEG' or fileExtension == 'JPG' then 
			sum = sum + 1
		end
	end

	return sum
end


function configureAndExport(exportContext, exportSession, exportParams, outputFolder, inputFolder, jobFolder)	
	
	-- Configure export context and set progress title	
	local progressScope = exportContext:configureProgress { 
		title = "Exporting "..exportSession:countRenditions().." picture(s)"		
	}
	
	-- Iterate through photo renditions		
	logger:trace ("Starting export... " .. jobFolder)

	for _, rendition in exportContext:renditions{ stopIfCanceled = true } do
		-- Wait for next photo to render.
		local success, srcFilePath = rendition:waitForRender()
		
		-- Check for cancellation again after photo has been rendered.
		if progressScope:isCanceled() then break end
		
		if success then
			copyPhoto(srcFilePath, outputFolder, rendition, jobFolder)
		end
	end
	
	progressScope:done()
	
	-- Give the UI a chance to finish updating itself before we block it with a message box
	LrTasks.sleep(0.2)
	
	local numOutputPics = getNumPhotosInFolder(outputFolder)	
	if numOutputPics == numberOfInputPics(inputFolder) then 
		LrDialogs.message("Export success", 
			"All pictures have been exported. Please remove "..inputFolder:getName()
			.." from Lightroom, but leave the files on disk.", 
			"info")
	else
		local numPicsLeft = numberOfInputPics(inputFolder) - numOutputPics
	
		LrDialogs.message("Some pictures were exported", 
			numOutputPics.." picture(s) exported. "..numPicsLeft.." picture(s) remain.",
			"warning")
	end 
end


function inputFolder()
	local folders = catalog:getActiveSources()
	
	if #folders ~= 1 then
		error "Please select one and only one folder for export, then try again."
	end
	
	return folders[1]
end

function numberOfInputPics(inputFolder)
	return #inputFolder:getPhotos(true)
end
