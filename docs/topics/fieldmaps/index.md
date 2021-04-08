# Field Map

The primary usage of the field map is to specify a mapping of fields from a source object to a destination object.   Currently String, Decimal, and Boolean values are supported.   

## Basic Usage

There are two types of metadata referenced by this class.
1. Field_Map__mdt - represents the mapping between any two Entities that salesforce will allow to map as entities.
2. User_Field_Map__mdt - represents the mapping from an Entity to an Event, Task, or User.


Normally, one starts by constructing the helper with the a unique name for the map.  A good unique name might be the name of your project or package.  For example:

```Field_Map fm = new Field_Map('Test_Map');```

Now go ahead and use this to copy fields from one object to another.

```
List<String> errors = fm.copyFields(source,destination);
```

If you need to know the field name in the mapping, say for a dynamic query:

```
Set<String> srcFieldNames = fm.getSourceFieldNames('',Account.SObjectType);
Set<String> destFieldNames = fm.getDestinationFieldNames('',Account.SObjectType);
```
