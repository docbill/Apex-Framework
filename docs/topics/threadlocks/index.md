# Thread Locks

Sometimes we need a way to prevent recursion. Some developers will simply use a static value in their class for that purpose.   However, that can create unnessary cross class dependencies.   To avoid that issue we have a ```ThreadLock``` class that more or less does the same thing.

## Basic Usage

The usage pattern of this is really simple.  If your code is completely in one method you can usually do a try/finally block like:

```
  	final String <MY_THREAD_KEY> = '<<<This is a unique value.>>>';
    if(ThreadLock.lock(<MY_THREAD_KEY>)) {
    	try {
   			// do some work
   		}
   		finally {
   			ThreadLock.unlock(<MY_THREAD_KEY>);
    	}
    }

````

The first gotcha is you want to use the same thread name everywhere that is mutually exclusive excution.  If you make your <MY_THREAD_KEY> variable public then you are introducing the same class dependency as just using a static boolean.

The second thing to watch out for is when you do a lock you also do an unlock.  Unless it really is intended that you want to make your block of code a singleton.  e.g. If your method is called again after exiting your method, you really don't want your code to run again.
