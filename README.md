# Introduction

This plugin will show repeated marc tags appended to the ouptut of reports on bibliographic records.

# Downloading

From the [release page](https://github.com/bywatersolutions/koha-plugin-repeatable-marc-report/releases) you can download the latest `*.kpz` file

# Installing

Koha's Plugin System allows for you to add additional tools and reports to Koha that are specific to your library. Plugins are installed by uploading KPZ ( Koha Plugin Zip ) packages. A KPZ file is just a zip file containing the perl files, template files, and any other files necessary to make the plugin work.

The plugin system needs to be turned on by a system administrator.

To set up the Koha plugin system you must first make some changes to your install.

* Change `<enable_plugins>0<enable_plugins>` to `<enable_plugins>1</enable_plugins>` in your koha-conf.xml file
* Confirm that the path to `<pluginsdir>` exists, is correct, and is writable by the web server
* Restart your webserver

Once set up is complete you will need to alter your UseKohaPlugins system preference.

# Using

* Create a report in the Koha reports module.
  * The report must have one column called `biblionumber`.
  * This column is used as a lookup for the specified tags and subfields. 

* Run the plugin.
  * Enter the report number for the you created above.
  * Enter the marc tag
  * Enter the marc subfield.
  * You may choose results in CSV or HTML
  * Voila!

