# Metadata Values Helper

The primary usage of the metadata values helper is to give developers a standardized way to use metadatat that maps primative objects.  Currently String and Decimal values are supported.   This avoids the need to add new metadata object for each project when there are only actually a few values that need to be configurable.


## Basic Usage

There are two types of metadata referenced by this helper class.
1. Decimal2_Values__mdt - represents Decimal numbers with 2 digits past the decimal place.
2. String_Values__mdt - represents String values.

By using the helper to access this data, are accessible like an in memory Map.  Sometime in the future we may add similar features to perform overrides like in the Boolean Values Helper.   But at least one can manually update the data in the maps thems selves for resource injection from test classes.

Normally, one starts by constructing the helper with the a unique name for the map.  A good unique name might be the name of your project or package.  For example:

```Metadata_Values_Helper mvh = new Metadata_Values_Helper('IE-ACTL');```

The helper will query all the metadata values with this source name and store them in an in memory map. e.g.

```
String myStringValue = mvh.stringMap.get('myValue');
Decimal myDecimalValue = mvh.decimalMap.get('myValue');
```

## Depreciated Usage

The creating of the maps directly rather than allocating the helper is discouraged, and should be considered depreciated functionality.   The reason being is this usage pattern will limit our ability to add overrides simmilar to the ```BooleanValuesHelper``` in the future.  The only reason these methods exist is originally this class was intended as a utility class instead of a helper class.
