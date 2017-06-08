--Describe a service export provider

require 'ExportTask'
-- require 'Config'

return {	
	hideSections = {
		'exportLocation',
		'watermarking', 
		'metadata',
		'fileNaming'
	},
	
	allowFileFormats = nil, -- nil equates to all available formats	
	allowColorSpaces = nil, -- nil equates to all color spaces
	
	-- builtInPresetsDir = "Preset",

	exportPresetFields = {
			{ key = "root", default = nil },
	},
	
	processRenderedPhotos = ExportTask.processRenderedPhotos,
}

