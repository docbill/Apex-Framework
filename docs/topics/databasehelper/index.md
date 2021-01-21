# Database Helper

The DatabaseHelper class is intended to simplify DML code to make it easier to follow best practices.  For each DML operations there are two modes "safe" mode and "legacy" mode.  The difference is in the type of list returned by the command.  The legacy commands will return a list of Database.SaveResult, Database.UpsertResult, Database.DeleteResult, Database.UndeleteResult respectively.   The safe mode returns a list of DatabaseHelper.Result classes irrespitve of which DML operation was called.  

## Usage

The general usage is you first construct the helper, then you set values to indicate how the database operation will be performed, and finally you call the DML.  A typical usage might be:

```
new DatabaseHelper()
    .setOptAllOrNone(true)
    .setCheckLimits(true)
    .setDeactivateTriggers(true)
    .legacyUpdate(recordList);
```

This particular call would have been almost equivalent to:

```
Boolean deactivateAll = BooleanValuesHelper.overrideSettingMap.get('DeactivateAll');
try {
    BooleanValuesHelper.overrideSettingMap.put('DeactivateAll',true);
    new LimitHelper()
        .setCpuTime(10)
        .setDmlStatements(1)
        .setDmlRows(recordList.size())
        .checkLimits( true );
    Database.update(recordList,true);
}
finally {
    BooleanValuesHelper.overrideSettingMap.put('DeactivateAll',deactivateAll);
}
```

Only the DatabaseHelper method usage was more concise and easier to read.

## DatabaseHelper.Result

All the safe methods use this custom return type. e.g.

```List<Database.Result> results = new DatabaseHelper.safeInsert(recordList);```

### Methods include:

```SObject getSObject()```  -- At last there is an easy way to return exactly what object in the list was being operated on.  

```List<Database.Error> getErrors()``` -- get the list of errors

```List<DatabaseHelper.ResultException> getExceptions()``` -- return the errors in a form of exceptions.


```Id getId()``` -- the record Id, if successful

```Boolean isSuccess()``` -- test if successuful

```Boolean isCreate()``` -- test if created

```List<String> getStackTraceStrings()``` -- return the stack traces foreach error.

Just having a single return type alone is a significant advantage in being able to reuse the same error processing code rather than having different error processing for different operations.

## Settings

The main reason to use this helper is because of the ability to set exactly how the dml operation will be performed, with useful settings.  All settings options return DatabaseHelper, so they settings can be chained as one command.   The setting methods include:

```assignOptions(List<SObject> recordList)``` -- When doing an upsert it is necessary to set DmlOptions on each record this gives us a way to do that.  An example usage would be:

```
new DatabaseHelper()
    .setAllowFieldTruncation(true)
    .assignOptions(recordList)
    .safeUpsert(recordList);
```

```setEnqueueScope(Integer value)``` -- this is a quick way to perform a dml operation in a Queueable chain rather than synchronously.  A negative value will just do excess records in a queueable job.   For example, if your code only supports 30 records in your trigger, you could use the following dml:

```
new DatabaseHelper().setEnqueueScope(-30).safeInsert(recordList);
```

If you have less than 30 records everything is synchronous.  If not the first 30 will be synchronous, and the rest processed in a Queueable job.

Note only one queueable process can be invoked.  So if that limit has already been reached, ```enqueueScope``` value will be ignored.

```setOptAllOrNone(Boolean value)``` -- pass a value of true if you wish to throw an exception on any error.

```setAllowFieldTruncation(Boolean value)``` -- set to true if you wish to automatically truncate text fields.

```setOptions(Database.DMLOptions value)``` -- set the same dml option value on all records.

```setDeactivateTriggers(Boolean value)``` -- set to true to perform the dml operation with the ```DeactivateAll``` value as true.

```setExternalIDField(Schema.SObjectField value)``` -- assign the external id field used by an upsert.

```setCheckLimits(Boolean value)``` -- Called to change the check limits property.


