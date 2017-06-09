User manual
=====================
The integration is built around two seperate Lightroom plugins, one for import and one for export.
It support two different main scenarios: 

1. *RetouchLink on a local server serving one or more retouch users*  
RetouchLink running on a server and is set to auto download jobs into a shared folder. The folder is then mapped on the computers the retoucher uses Ligthroom  on, and the users use the plugins to get next available job and export when finished. The plugins is then handling that not multiple users are working on the same jobs, etc.

2. *One RetouchLink per retouch user*  
The plugins are not need in this case, but it helps the user dong the right things. It also has the benifit of the verification rules that can be set on export. For example that the exported images are in AdobeRGB or sRGB.


# Requirements

## Adobe Lightroom
This is an plugin integration for Adobe Lightroom and therefore requires that Lightroom already is installed on the computer before this is installed.

## Retouch Link
For this plug-in to work certain settings has to be set in the RetouchLink.
* Use default *Image file name* pattern
* The *Use output directory* must be checked.
* Retouch Link version must be 2.0.0 or higher

# Installation
We support two ways to install the plug-ins;with an installer and  manually.

##  Setup program (only windows)
During the installation you have to point it to the folder where Retouhc Link exports the  jobs.
![Choose the folder where Retoruc Link exports jobs](installer-RL-folder.PNG?raw=true "Choose folder")

The installer finds the *Modules* folder for Lightroom and adds the plugins there. On windwows this is usually ` *%AppData%\Roaming\Adobe\Lightroom\Modules* `. You can find the paths for the plugins from the *Lightroom Plug-in Manager* (File->Plug-in Manager)

![Plug-in Manager](plugin-manager.png?raw=true "Plug-in Manager")
It also shows if something is wrong with the plugins and you can turn on diagnostic logging.

## Manually
The zip file with the plugins have following structure: 
- plugins 
    - NetlifeExport.lrplugin 
    - NetlifeImport.lrplugin 

1. Unzip the the file to a location where you want to have the plugins
2. Start Lightroom and goto `Plug-ins Manager`
3. Add first the import plugin and then the export plugin
4. Configure the plugins with at least the folder where retouch link puts jobs and userid


[More info about how to manage Lightroom plugins](https://helpx.adobe.com/lightroom/how-to/lightroom-use-manage-plugins.html)

# Configuration
The configuration is stored in a common file for both of the plugins in this workflow. The location is found from the `Plug-in Manager` in Lightroom.
* *input*  
The path to the RetouchLink output folder, example `c:\my retouch jobs`.
* *user*  
Is the user id  of the operating system user that runs the installation program. Is used in the job marker files to identify the user that has taken the job. This must be unique for each user.
* *dbg*  
Possible values are `false` and `true` If set to true the plugins log more and show dialog messages when they are ran. 
* *charsReservedToCompanyPrefix*  
Number of the first characters in the jobname are used for company/portal prefix. Default value is `0`. The prefix per company/portal on a job are configured in Retouch Link. If this is set to zero, all company settings and rules are ignored.
* *allowedCompanies*  
List of the prefix of the jobs this user should get. Example `{"c1-","c2-","c3-"}`. If no filter the value must be `{}`. (This is only used by the import plugin). If the list is empty, jobs for all companies are grabbed.
* *companyExportSettings*  
Define company spesific rules that is validated against properties in the exportContext.propertyTable. If `dbg = true` all possible values are printed in the log file.  (this is only used by the export plug-in)

Note that if you manually change the config settings you will have to reload the plug-ins in Lightroom.

# Import
The plugin imports the next job that is not already taken based on following criterias:
- company filter: only jobs with a prefixed with a company prefix the user supports.
- the jobs are sorted on priority (see priority.txt in the job folder) and descending on folder creation time. The jobs can be set to have high priortity in QA.

The menu item to import is found at *File*->Plug-in extras ![Get next job](import-menu.png?raw=true "Get next job")

If a job is available Lightroom will start importing the pictures, and this can take some time. If no jobs are available you will get a message box saying that.

![No jobs-available message dialog](no-jobs-available.PNG?raw=true "No jobs-available message")

# Export
Exports the job to an output folder inside the original source folder. When selecting the images to export make sure to do it from the folder, not a Catalog og Collection.
![Source folder](folders.PNG?raw=true "Select the folder")

Make sure to select the correct settings for the export
![Lightroom export dialog](export.png?raw=true "Export dialog")


If some images are missing, it shows a messages informing about how many images that is not exported yet. If all are exported it shows a messages saying that and tells you to manually remove the folder from Lightroom, but leave the files on disk. Successfully exported images are marked as green in Lightroom, to help you decide which images are exported.

It validates the export settings based on the rules defined in `companyExportSettings` in the config file. 


# FAQ
## No jobs are imported, but I know that at least one is available
The cause could be that the plugins are configured with wrong RetouchLink path or with company filter.
