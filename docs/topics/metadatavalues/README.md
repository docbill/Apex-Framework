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
## Array Design Pattern 

1. Define the values like a map of array values in String_Values__mdt.  e.g.

| Label                           | Source                  | Key     | Value                                                           | Active  |
| :------------------------------ | :---------------------- | :------ | :------------------------------------------------------------:  | :-----: |
| IE_ACTL_After.reprocess.value01 | IE_ACTL_After.reprocess | value01 | ```(?i)Aggregate query.*```                                     |	Checked |	 
| IE_ACTL_After.reprocess.value02 | IE_ACTL_After.reprocess | value02 | ```(?i).*Limit Exceeded.*```                                    | Checked |	 
| IE_ACTL_After.reprocess.value03 | IE_ACTL_After.reprocess | value03 | ```(?i).*Limits:.*out of.*```                                   | Checked |	 
| IE_ACTL_After.reprocess.value04 | IE_ACTL_After.reprocess | value04 | ```(?i).*Regex too complicated.*```                             | Checked |	 
| IE_ACTL_After.reprocess.value05 | IE_ACTL_After.reprocess | value05 | ```(?i).*unable to obtain exclusive access to this record.*```  | Checked |	 
| IE_ACTL_After.reprocess.value06 | IE_ACTL_After.reprocess | value06 | ```(?i).*Unable to persist SalesAccount data.*```	              | Checked |	

2. In your code retrieve the list of active values by name:

```
Metadata_Values_Helper reprocessHelper = Metadata_Values_Helper
  .getMetadataValuesHelper('IE_ACTL_After.reprocess')
List<String> List reprocessList = reprocessHelper.stringMap.values();
```

3. If you want to quickly find and update your values, create a list view for String_Values__mdt.

## Map Design Pattern 

1. Define the values like a map of values in String_Values__mdt.  e.g.

| Label                             | Source          | Key               | Value               | Active  |
| :-------------------------------  | :-------------- | :---------------- | :-----------------: | :-----: |
| APTS_SKU_Status.Active            | APTS_SKU_Status | Active            | Activated           | Checked |	 
| APTS_SKU_Status.Entered           | APTS_SKU_Status | Entered           | Ready for Renewal   | Checked |	 
| APTS_SKU_Status.Expired           | APTS_SKU_Status | Expired           | Expired             | Checked	|
| APTS_SKU_Status.QA Hold           | APTS_SKU_Status | QA Hold           | QA Hold             | Checked	|
| APTS_SKU_Status.Signed            | APTS_SKU_Status | Signed            | Signed              |	Checked	|
| APTS_SKU_Status.Terminated        | APTS_SKU_Status | Terminated        | Terminated          | Checked | 
| APTS_SKU_Status.Termination Hold  | APTS_SKU_Status | Termination Hold  | Pending Termination	| Checked |	 

2. In your code retrieve the map of active value, and respective values:

```
Metadata_Values_Helper skuStatusHelper = Metadata_Values_Helper
  .getMetadataValuesHelper('IE_ACTL_After.reprocess')
String active = skuStatusHelper.stringMap.get('Active');
String entered = skuStatusHelper.stringMap.get('Entered');
String qaHold = skuStatusHelper.stringMap.get('QA Hold');
...
String terminationHold = skuStatusHelper.stringMap.get('Termination Hold');
```

4. If you want to see just your list in the String_Values__mdt, add a respective list view.


## Depreciated Usage

The creating of the maps directly rather than allocating the helper is discouraged, and should be considered depreciated functionality.   The reason being is this usage pattern will limit our ability to add overrides simmilar to the ```BooleanValuesHelper``` in the future.  The only reason these methods exist is originally this class was intended as a utility class instead of a helper class.
