# Unlocked Package Instructions

You can use the unlocked packages Red Hat has built that are listed in the sfdx-project.json file, but this is NOT RECOMMENDED.   The biggest reason is these builds are against an organization Red Hat will be retiring, which will eventually make upgrade installs impossible.  But also because you probably want your builds tested and approved by your processes.

The easiest way to keep your own sfdx-package.json without maintaining your own fork is to create add this a submodule to another git repository.  We'll outline those steps first.

## Adding as Submodule

Start off with our existing vscode project or create a new vscode project. Do not forget to initialize the git repo is that has not been done.   You can now create a folder for submodules and add this module:

```
$ mkdir submodules
$ cd submodules
$ git submodule add <clone url>
```

## Update sfdx-project.json

The next step is to update your sfdx-project.json with your package info.   You can if you wish directly copy and paste this into your projects sfdx-project.json and then edit the path.   It will look something like:

```
        {
            "path": "submodules/ApexFramework/src/apexframework",
            "default": false,
            "package": "ApexFramework",
            "versionName": "ver 1.2",
            "versionNumber": "1.2.0.NEXT"
        }
```

Be sure to use the current version number and version name.

## Create Package On Your DevHub

You should now create the package on your devhub.

```sfdx force:package:create -t Unlocked -d "Artifacts used for triggers,dml,limits,metadata etc" -r submodules/Apex-Framework/src/apexframework/ -n ApexFramework```

## Build a Version

Assuming you have the branch checked out for your submodule you want to build, you can create the new version:

```sfdx force:package:beta:version:create -x -c -p ApexFramework --wait 1000```

Note the install link.  You can modify that link and use it to install your version on the respective sandbox, if you have the appropriate permissions.  Otherwise you will need to give the link to devops.   You can also use the ```sfdx force:package:install``` command.  For example to install to merge:

```sfdx force:package:install --package "ApexFramework@<version>" -s AllUsers -w 1000 -u merge```

We have not tested the package installed without the AllUsers flag.  But of course you are managing your permission with permission sets, you probably will want to test this.

## Promote Your Package

When you are ready, be sure to promote your version for production.   Note: You can only have one promoted build per version.  So if you make a mistake, you'll need to update the version number.  As such, your version numbers may not match the version numbers used in Red Hat's builds.
