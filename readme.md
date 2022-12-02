# uga-archivesspace-reports
A collection of custom reports built for UGA's ArchivesSpace instance. The following reports are:

- **check_urls** - A custom report to capture URLs in notes and digital object file versions and check them for bad 
requests (404, 500, etc.). Redirected links check the destination URL for errors.

# Getting Started

Download the files in this repo by clicking on the Code box in the top right corner and selecting Download ZIP.

Move the downloaded ZIP folder to your ArchivesSpace's plugins path:

    /path/to/archivesspace/plugins

Unzip it:

    $ cd /path/to/archivesspace/plugins
    $ unzip uga-archivesspace-reports-main.zip -d uga-archivesspace-reports-main

Enable the plugin by editing the file in `config/config.rb`:

    AppConfig[:plugins] = ['some_plugin', 'uga-archivesspace-reports-main']

(Make sure you uncomment this line (i.e., remove the leading '#' if present))

For more information on installing and making plugins:

https://github.com/archivesspace/tech-docs/blob/master/customization/plugins.md

## check_urls

If you just want the check_urls report, rename the unzipped folder from "uga-archivesspace-reports-main" to "check_urls"
in the plugins folder.

Enable the plugin by editing the file in `config/config.rb`:

    AppConfig[:plugins] = ['some_plugin', 'check_urls']

> NOTE: If there's more than the check_urls report in this repo, there are additional steps. You will need to go into 
> the unzipped folder, go to backend/model and delete all the additional .rb files except check_urls (or whichever you 
> want). Then, you will need to edit the en.yml file (frontend/locales/en.yml) to delele all other reports except 
> check_urls (or the one you want). Make sure to follow these steps again if updating the plugin.