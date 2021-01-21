# Limit Helper

The primary usage of the limit helper is a usable way to check limits and to throw a catchable exception before a limit has been reached rather than an uncatchable exception after a limit has been reached.

This is of particular importance for triggers on standard objects.  As hitting the limit means your record is not even persisted in salesforce.   It is impossible to fallback to using asynchronous processing once you hit a governor limit.  So we need a standardized way to check for a limit before it happens, so that code with a way to handle the processing differently can do so.  And even code that has no other way of processing the record can at least store a meaningful error.

## Basic Usage

The general usage pattern involves setting reserved limits.   This is normally done in a try/catch/finally block as follows:

```
    static final String <MY LIMITS SETTING> = '<whatever you named it>';
    try {
        if(<someEntryCondition>) {
            LimitHelper.push(<MY LIMITS SETTING>);
        }
        ...
    }
    catch(LimitHelper.LimitsException ex) {
        ...
    }
    finally {
        if(<someEntryCondition>) {
            LimitHelper.pop(<MY LIMITS SETTING>);
        }
    }
 ```

So for example you had an asynchronous solution for when you have more than one record.   A typical entry condition might be: ```newList.size() > 1``` 

The catch exception or an after trigger is where you can add code to use deferred processing to handle one record at the time so you do not hit the limits.


The LimitHelper name you are pushing and poping is the master label of the ```Limit_Reserves__mdt``` record that defines what how much time you reserving.   Your ```Limit_Reserve__mdt``` record should reserve whatever limits you need to make sure your catch block can still succeed as well as the rest of the processing flow after your try/catch/finally block.  

Then in order for this code to work there needs to be calls to the LimitHepler class to check the limits periodically.  For example, immediately before a query you could call:

```
    (new LimitHelper()).setQueries(1).checkLimits( null);
```

This is saying check the limits and make sure we have one query available beyound the reserve.  If we do not either return an Exception or throw an exception.  The null argument is the boolean that tells the helper if it should throw the exception.  If you pass true, it will throw the exception.  If you pass false, it will return the exception.

Using a null value is equivalent to:

```
(new LimitHelper()).setQueries(1).checkLimits( LimitHelper.throwsExceptionDefault );
```

There are a series of DatabaseHelper.safe* methods that can be used to automatically check the limits when performing DML operations.  e.g.

```
    for(DatabaseHelper.Result r : new DatabaseHelper().safeInsert(insertList)) {
        if(r.isSuccess()) {
            ...
        }
    }
```

By default we are checking a whole bunch of limits each time, but there are static methods in the LimitHelper class for checking individual limits.
