local LrDialogs = import 'LrDialogs'
local configurationManager = require 'ConfigurationManager'
local Config = configurationManager.getConfig()

local LrView = import "LrView"
local bind = LrView.bind -- shortcut for bind() method
local LrHttp = import "LrHttp"

local LrPathUtils = import 'LrPathUtils'
local LrFileUtils = import 'LrFileUtils'
local LrColor = import 'LrColor'
local LrTasks = import 'LrTasks'
local LrSystemInfo = import 'LrSystemInfo'
 
local PluginInfoProvider = {}

local configInfoSection = function(f, propertyTable) 
	local configInfo 
	local color 
	local configpath = configurationManager.getConfigFilePath()
	if LrFileUtils.exists(configpath) then
		configInfo = "Config file is stored at:"
		color = LrColor( 0, 0, 1 )
	else
		configInfo = "Config will be stored at:"
		color = LrColor( 1, 0, 0 )
	end
	
	return f:row {
		
		spacing = f:control_spacing(),
		f:static_text {
			title = configInfo,
			fill_horizontal = 1,
		},
		f:static_text {
			text_color = color,
			title = configpath,
			fill_horizontal = 1,
			--selectable = true,
			mouse_down = function (v)
				
				local os = string.lower(LrSystemInfo.osVersion())
				local copyCmd = "echo '"..configpath.."' | pbcopy"
				
				if string.find(os, "windows")  then
					copyCmd = "Echo "..configpath.." | clip"
				end
		
				-- the copy works but no messages are shown....
				if (LrTasks.execute(copyCmd) == 0) then
					LrDialogs.message("Copied file path to clipboard")
				else
					LrDialogs.message("Failed to copy...")
				end
			end	
						
		}
			
	}

end 

local userSection = function(f, propertyTable) 
	return	f:row {
			spacing = f:control_spacing(),
				f:static_text {
					title = "User (MUST be UNIQUE for each user \nworking against the same Lablink installation)",
					tooltip = "The user id each job are marked with when a job are locked by this plugin",
					height_in_lines = 2,
					fill_horizontal = 1,
				},
				f:edit_field { -- create edit field
					width = 150,
					bind_to_object = Config,
					value = bind 'user', -- bound to property
					immediate = true -- update value w/every keystroke
				}
			}

end

local inputFolderSection = function(f, propertyTable) 
	return f:row {
		bind_to_object = Config,
		spacing = f:control_spacing(),
		tooltip = "The folder where the plugin will look for new jobs",
		f:static_text {
			title = "Jobs input folder",
			fill_horizontal = 1,
		},
		f:edit_field {
			width = 150,
			value = bind 'input',
			immediate = true ,
			tooltip = "Example values 'k:\jobs' on windows and '/home/jobs' MAC"

		},
	}

end

local debugSection = function(f, propertyTable) 
	return f:row {
		spacing = f:control_spacing(),
		f:static_text {
			title = "Log debug info",
			fill_horizontal = 1,
		},
		f:checkbox {
			tooltip = "tooltip",
			bind_to_object = Config,						
			width = 150,
			value = bind 'dbg', -- bind to the key value
			checked_value = true, -- this is the initial state
			unchecked_value = false, -- when the user unchecks the box,
			-- this becomes the value, and thus
			-- the bound key value as well.
		}, 
	}
end


local saveSection = function(f, propertyTable) 
	return 	f:row {
		spacing = f:control_spacing(),
		f:push_button {
			width = 150,
			title = "See online user manual",
			tooltip = "See the online user manual",
			enabled = true,
			action = function()
				LrHttp.openUrlInBrowser( 'https://github.com/NetlifeAS/lightroom-integration/blob/master/doc/manual.md')
			end,
		},
		f:push_button {
			width = 150,
			title = "Save the settings",
			tooltip = "Save the settings for later use",
			enabled = true,
			action = function()
				configurationManager.storeConfig(Config)
			end,
		}
			
	}

end 

local usermanualSection = function(f, propertyTable) 
	return f:row {
		spacing = f:control_spacing(),
		
		f:static_text {
			width = 300,
			title = "This is shared configuration between the two plugins used in the Netlife workflow. Without correct configuration the plugins will not work.\n \nSee online manual for more information.",
			fill_horizontal = 1,
			height_in_lines = 4,
			wraps=true
		}

	}


end 


local companyInfoSection = function(f, propertyTable) 
	return	f:row {
		spacing = f:control_spacing(),
		f:static_text {
			width = 300,
			height_in_lines = 3,
			title = "It is not mandatory to use the company section. It provide the function to say that a operator only should get jobs from some of multiple companies. It also makes it possible to add export rule checks, to veriy that the operator has set the correct export settings.",
			fill_horizontal = 1,
		}
	}
end

local companyPrefixSection = function(f, propertyTable) 
	return	f:row {
		spacing = f:control_spacing(),
		bind_to_object = Config,
		f:static_text {
			width = 150,
			title = "Chars reserved to company prefix (0 = no companies)",
			fill_horizontal = 1,
		},
		f:edit_field { -- create edit field
			tooltip = "Must be a number from 0 to 10",
			width = 150,
			precision = 0,
			increment = 1,
			min = 0,
			max = 10,
			value = bind 'charsReservedToCompanyPrefix', -- bound to property
			immediate = true -- update value w/every keystroke
		}				
	}
end


local allowedCompaniesSection = function(f, propertyTable) 

	local companies = ""
	for k, company in pairs (Config.allowedCompanies) do
		if companies == "" then
			companies = company 
		else
			companies = companies .. ", " .. company 
		end
	end 

	if companies == "" then
		companies = "No company filter defined"
	end
	
	return f:row {
				spacing = f:control_spacing(),

				f:static_text {
					title = "AllowedCompanies (empty mean all is companies are allowed)",
					fill_horizontal = 1,
				},
				f:static_text {
					width = 150,
					title = companies,

				},
			}

end 

local companyExportSettingsSection = function(f, propertyTable) 

	-- Config.companyExportSettings	
	return f:row {
		spacing = f:control_spacing(),
		f:static_text {
			title = "CompanyExportSettings ",
			fill_horizontal = 1,
		},
		f:static_text {
			width = 150,
			title = "see the config file",
		}
	}

end 
	
	
function PluginInfoProvider.sectionsForTopOfDialog (f, propertyTable )
	
	local gui =  {
		-- Section for the top of the dialog.
		{
			title = "Netlife Workflow Plugins",
			usermanualSection(f, propertyTable),
			userSection(f, propertyTable),
			inputFolderSection(f, propertyTable),
			debugSection(f, propertyTable),
			companyInfoSection(f, propertyTable),		
			companyPrefixSection(f, propertyTable),
			allowedCompaniesSection(f, propertyTable),
			companyExportSettingsSection(f, propertyTable),
			configInfoSection(f, propertyTable),
			saveSection(f,propertyTable)
		},

	}
		
	return gui
end


return PluginInfoProvider
