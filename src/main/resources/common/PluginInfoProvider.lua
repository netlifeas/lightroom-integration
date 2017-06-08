local LrDialogs = import 'LrDialogs'
local configurationManager = require 'ConfigurationManager'
local Config = configurationManager.getConfig()

local LrView = import "LrView"
local bind = LrView.bind -- shortcut for bind() method
local LrHttp = import "LrHttp"

local LrPathUtils = import 'LrPathUtils'


local PluginInfoProvider = {}

function PluginInfoProvider.sectionsForTopOfDialog ( f, propertyTable )
	return {
			-- Section for the top of the dialog.
			{
				title = "Netlife Workflow Plugins",
				f:row {
					spacing = f:control_spacing(),

					f:static_text {
						title = "See online manual",
						fill_horizontal = 1,
					},

					f:push_button {
						width = 150,
						title = "User manual",
						tooltip = "See the online user manual",
						enabled = true,
						action = function()
							LrHttp.openUrlInBrowser( 'https://github.com/NetlifeAS/lightroom-integration/blob/master/doc/manual.md')
						end,
					},
				},
				f:row {
				spacing = f:control_spacing(),
					f:static_text {
						title = "User (MUST be UNIQUE for each user working against the same Lablink installation)",
						tooltip = "The user id each job are marked with when a job are locked by this plugin",
						fill_horizontal = 1,
					},
					f:edit_field { -- create edit field
						width = 150,
						bind_to_object = Config,
						value = bind 'user', -- bound to property
						immediate = true -- update value w/every keystroke
					}
				},
				f:row {
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
				},
				f:row {
					spacing = f:control_spacing(),
					bind_to_object = Config,
					f:static_text {
						width = 150,
						title = "Chars reserved to company prefix",
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
					
				},
				f:row {
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
				},
				f:row {
					spacing = f:control_spacing(),

					f:static_text {
						title = "AllowedCompanies",
						fill_horizontal = 1,
					},
					f:static_text {
						width = 150,
						title = Config.allowedCompanies,

					},
				},
				f:row {
					spacing = f:control_spacing(),

					f:static_text {
						title = "companyExportSettings",
						fill_horizontal = 1,
					},
					f:static_text {
						width = 150,
						title = Config.companyExportSettings,

					},
				},
				f:row {
					spacing = f:control_spacing(),

					f:push_button {
						width = 150,
						title = "Save the settings",
						tooltip = "Save the settings for later use",
						enabled = true,
						action = function()
							
							configurationManager.storeConfig(Config)
						end,
					},
					
					f:static_text {
						title = configurationManager.getConfigFilePath(),
						fill_horizontal = 1,
					},
		
				}
				
			},
	
		}
end



return PluginInfoProvider
