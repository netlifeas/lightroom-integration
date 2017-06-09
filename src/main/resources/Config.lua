Config = {
    input = "JOB_SOURCE_FOLDER",
    user = "USERID", -- inserted by NSIS
    dbg = false, -- show debug message boxes
	-- you can define rules  for wich portals this client should get based on portal prefix 
	allowedCompanies = {}, -- example on company filter {"c1-","c2-","c3-"},
	charsReservedToCompanyPrefix = 0, -- number of the first chars that is reserved to company(portal) prefix 
	-- define company spesific rules that is validated against properties in the exportContext.propertyTable. If dbg = true all possible values are printed in the log file. 
	companyExportSettings =
		{
			["c1-"] = { ["LR_export_colorSpace"] = "sRGB" },
			["c2-"] = { ["LR_export_colorSpace"] = "AdobeRGB"},
			["c3-"] = { ["LR_export_colorSpace"] = "AdobeRGB"},
		}
}

