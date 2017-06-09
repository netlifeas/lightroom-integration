local LrDialogs = import 'LrDialogs'
local LrPathUtils = import 'LrPathUtils'
local LrFileUtils = import 'LrFileUtils'

local configurationManager = {}

local addEntry = function (fd, prop, value, marker, comment)
	fd:write('\t')
	fd:write(prop)
	fd:write(' = ')
	if marker == '"' then
		string.format('%q', value)
		fd:write(string.format('%q', value), ',  -- ', comment, "\n")
	else
		fd:write(marker, value, marker, ',  -- ', comment, "\n")
	end
end 

local addCompanyExportSettings = function (fd, companyExportSettings) 
	fd:write('\t-- define company spesific rules that is validated against properties in the exportContext.propertyTable. If dbg = true all possible values are printed in the log file. ', "\n")
	fd:write('\t', 'companyExportSettings = {', '\n')
	
	for company, rules in pairs (companyExportSettings) do
		fd:write('\t\t["', company , '"] = {')	
				for property, value in pairs (rules) do	
					fd:write('["', property , '"] = ')
					fd:write('"', value , '",')
				end
		fd:write(' },', '\n' )	
	end 
	
	fd:write('\t}', "\n")
end


local addAllowedCompanies = function (fd, allowedCompanies) 
	fd:write('\t-- example on company filter: allowedCompanies = {"c1-","c2-","c3-"}', "\n")
	fd:write('\t', 'allowedCompanies = {')
	for k, v in pairs (allowedCompanies) do
		fd:write("'", v , "',")	
	end 
	
	fd:write('},', "\n")
end

function configurationManager.getConfigFilePath()
	local apprefsPath = LrPathUtils.getStandardFilePath("appPrefs")
	apprefsPath = LrPathUtils.child(apprefsPath, 'netlife-plugin-config')
	apprefsPath = LrPathUtils.addExtension(apprefsPath, '.lua')
	return apprefsPath
end

function configurationManager.getConfig()
	local configpath = configurationManager.getConfigFilePath()
	if LrFileUtils.exists(configpath)  then
		dofile (configpath)
	else
		require 'Config'
	end
	return Config
end

function configurationManager.storeConfig(config )

	local fd, msg = io.open(configurationManager.getConfigFilePath(), 'w')

	if not fd then 
		LrDialogs.message("Failed to save settings: " ..  msg)
		return
	end
	fd:write('Config = {', "\n")
	
	addEntry(fd, 'input', config.input, '"', 'folder where the jobs are output by Lablink')
	addEntry(fd, 'user', config.user, '"', 'user id that is used to lock a job for other users when a job are grabbed')
	
	local dbgvalue
	if config.dbg then 
		dbgvalue = 'true'
	else
		dbgvalue = 'false'
	end 
	addEntry(fd, 'dbg', dbgvalue, '', 'show debug message boxes')
	
	fd:write("\n", '\t-- you can define rules  for wich portals this client should get based on portal prefix', "\n")
	addEntry(fd, 'charsReservedToCompanyPrefix', config.charsReservedToCompanyPrefix, '', 'number of the first chars that is reserved to company(portal) prefix ')
	
	addAllowedCompanies(fd, config.allowedCompanies)
	addCompanyExportSettings(fd, config.companyExportSettings)
	
	fd:write('}')
	fd:close()
	LrDialogs.message("Settings are saved.")
	
end
 
return configurationManager