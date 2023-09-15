# Overview
A collection of custom reports built for UGA's ArchivesSpace instance. The following reports are:

- **check_urls** - A custom report to capture URLs in notes and digital object file versions and check them for bad 
requests (404, 500, etc.). Redirected links check the destination URL for errors.

# Getting Started

## Dependencies

### check_urls
- [json](https://ruby-doc.org/stdlib-2.6.3/libdoc/json/rdoc/JSON.html) - Used to parse the JSON data found in notes
- [uri](https://ruby-doc.org/core-3.1.2/Gem/Uri.html) - Used to handle URLs
- [Net::HTTP](https://ruby-doc.org/stdlib-3.0.1/libdoc/net/http/rdoc/Net/HTTP.html) - Used to make HTTP requests and 
return any errors from broken URLs

## Installation

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

### check_urls

If you just want the check_urls report, rename the unzipped folder from "uga-archivesspace-reports-main" to "check_urls"
in the plugins folder.

Enable the plugin by editing the file in `config/config.rb`:

    AppConfig[:plugins] = ['some_plugin', 'check_urls']

> NOTE: If there's more than the check_urls report in this repo, there are additional steps. You will need to go into 
> the unzipped folder, go to backend/model and delete all the additional .rb files except check_urls (or whichever you 
> want). Then, you will need to edit the en.yml file (frontend/locales/en.yml) to delele all other reports except 
> check_urls (or the one you want). Make sure to follow these steps again if updating the plugin.

## Workflow

### check_urls
1. User initiates the Check URLs Report within the ArchivesSpace staff interface
2. The script will run through a check for each part of the ArchivesSpace database likely to have URLs. These include:
   1. Digital Object File Versions
   2. Resource notes
   3. Archival Object notes
   4. Digital Object notes
   5. Digital Object component notes
   6. Subject Scope and Contents notes
   7. Agent Person notes
   8. Agent Corporate Entity notes
   9. Agent Family notes
   10. Agent Software notes
3. Query the database using SQL statements to grab data containing information relating to the above data, as well as the
repository and identifiers where necessary
4. Take the query and use fetch_notes() to grab the results across all repositories and filter the results based on the 
data type, parameters include if it is a digital object, if the notes should be parsed using JSON, and if the titles
of the data should be checked as well
5. grab_urls() will attempt to go through the data be it JSON-parsed notes and subnotes and call match_regex to find
any text that may be a URL
6. Any potential matches are sent to check_urls() to format into a URI and pass it to Net:HTTP to get a response, 
following any redirects up to 5 times. Any errors are recorded and their responses are added to the results data
returned to the user in the report
7. If a user selected CSV as the output type in ArchivesSpace (the recommended type), then the user should get a report
containing the repository, Resource ID, Parent title, URL, and URL error code

## Author

- Corey Schmidt - Project Management Librarian/Archivist at the University of Georgia Libraries

## Acknowledgements

- ArchivesSpace Community
- Kevin Cottrell - GALILEO/Library Infrastructure Systems Architect at the University of Georgia Libraries