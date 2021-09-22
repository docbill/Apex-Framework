# Apex Framework

This is a package of framework entities used by Apex coding standards, that should make it easier to follow best practices.  It is expected that most unlocked packages will have access to this framework by either a direct package dependency, or by org based dependency.   If for some reason neither is appropriate for your project, some of the components in this package may still be accessed by reflection and salesforce interfaces.

## Release 1.2

This is the initial open source release of this package.  This is based on code in Red Hat's production org.  Depreciated code has been removed from this release.  Everything remaining is believed to be of interest for the open source community.

## Class Overview

### BooleanValueHelper

This is a class to allow easy configuration of boolean values based on a unique string name.  Normally, one will provide a prefix to limit which settings are being referenced.

See Also: [Boolean Values](docs/topics/booleanvalues/)

### DatabaseHelper

This is an enhancement for the salesforce Database object that allows automatic governor limit checks, better error tracking, and trigger deactivation.   It is a good idea to use this helper to simplify your code, and to better handle governor limit exceptions.

See Also: [Database Helper](docs/topics/databasehelper/)
### Field_Map

This is a simple class for specifying fields to copy from one object to another in a matadata map.

See Also: [Field Map](docs/topics/fieldmaps/)

### LimitHelper

This is a helper class to detect and throw catchable exceptions before a governor limit exception can happen.  Using this class will help make your code more robust when called from bulk operations.

See Also: [Limits](docs/topics/limits/)

### Metadata_Values_Helper

Simmilar to BooleanValueHelper, this is a simple class for String and Decimal configuration settings presented like a map.

See Also: [Metadata Values](docs/topics/metadatavalues/)

### SObjectCallableTrigger

This is a trigger handler to reimplement functionality that was normally done as part of AbstractTrigger.   This will eventually allow us to deprecated AbstractTrigger, but in the mean time it makes a good reference trigger implementation for the new framework.

See Also: [Callable Triggers](docs/topics/callabletriggers/)

### ThreadLock

Uses a static set to give us real simple thread locking.  Usually this is to avoid recursion inside trigger handlers.

See Also: [Thread Lock](docs/topics/threadlocks/)

### TriggerArguments

This is a replacement for the standard Trigger object in salesforce.  Unlike the standard Trigger the values in TriggerArguments can be assigned without need for a DML operation.  So trigger handler code can be more easily unit tested.

See Also: [Callable Triggers](docs/topics/callabletriggers/)

### TriggerManagment

This is a management class for ordering and invoking the appropriate trigger handler methods implemented with a Callable interface.

See Also: [Callable Triggers](docs/topics/callabletriggers/)

## Object Overview

### BooleanHierachy__c

This is a hierachy based metadata one can use to temporary define a role, profile, or user based override of any boolean metadata value set to default simply by create a field with the appropriate API name.  Most commonly this is used in release processes where certain triggers should not fire during data migration, and development testing where triggers are not ready for general use.

See Also: [Boolean Values](docs/topics/booleanvalues/), [Callable Triggers](docs/topics/callabletriggers/)

### BooleanMetadata__mdt

This is metadata settings for boolean values available as a map in the BooleanValueHelper class.  These values are normally used so that apex code can be toggled between an active and inactive state.  This allows one to deploy code in a deactivated state and activate once the business is ready for the new functionality.  This may also be used to deactivate code that is considered depreciated, but still maybe needed in the future.

See Also: [Boolean Values](docs/topics/booleanvalues/), [Callable Triggers](docs/topics/callabletriggers/)

### Decimal2_Values__mdt

This is decimal metadata map accessible with the Metadata_Values_Helper__c with two decimal places.  Usually this is used to define currency thresholds and other two decimal values.

See Also: [Metadata Values](docs/topics/metadatavalues/)

### Limit_Reserve__mdt

This defines a limit set for your code.  The general usage is say you have two triggers that run to back to back.  If you want to reserve 2 queries for the next trigger, this will update the LimitHelper to take this in account when it is doing a limits check.

See Also: [Limits](docs/topics/limits/)

### String_Values__mdt

This is String metadata map accessible with the Metadata_Values_Helper__c.  Usually this is used in filters to select values, or constants that will be input into code.

See Also: [Metadata Values](docs/topics/metadatavalues/)

### Trigger_Management_Entry__mdt

This is a mapping of callable trigger methods, the sequences, and trigger events types which should invoke them.   The TriggerManagement class will reference this table to decide when to call each handler.

See Also: [Callable Triggers](docs/topics/callabletriggers/)

## Trigger Overview

### AttachmentTriggerManagement

This is a trigger for the new callable trigger framework that calls the TriggerManagement class for any Attachment DML operations.   This particular object was choicen for our framework, because at least one object trigger was needed to completely test our code, and none of the existing Attachment triggers in our org used the legacy framework.

See Also: [Callable Triggers](docs/topics/callabletriggers/)

## TestSuite Overview

The ApexFramework.testSuite is an easy way to test all the classes included in this package.

## Script Overview

### mdapi-deploy

This script may be used to deploy this package as an unmanaged package.  Say you wish to deploy to dev1  You would run the command:

```./mdapi-deploy ApexFramework -u dev1```

One could also deploy unpackaged data by specifing the folder. e.g.

```./mdapi-delpoy force-app -u dev1```

The folder name must be declared in the sfdx-project.json file for this to work.

## Package Version Creation and Deployment

When you are ready to go to MERGE, QA, STAGE, and even PROD you are going to need an unlocked package version.  To create a new version edit the sfdx-project.json file should there be an update to your major version number. e.g. 1.2 to 1.3.  Once your major version is set you can create the version with the command:

```sfdx force:package:version:create -x -p apexframework -d apexframework-app -c -p ApexFramework -d apexframework-app/ --wait 1000 -x -v DevHub```

Note the install link.  You can modify that link and use it to install your version on the respective sandbox, if you have the appropriate permissions.  Otherwise you will need to give the link to devops.   You can also use the ```sfdx force:package:install``` command.  For example to install to merge:

```sfdx force:package:install --package "ApexFramework@<version>" -s AllUsers -w 1000 -u merge```

Which ever way you choose to install, make sure you enable this package for all users.

