/**
 * This is a class for thread locking.   The normal usage is:
 * 
 * <pre>
 * 	final String MY_THREAD_KEY = '<<<This is a unique value.>>>';
 *  if(ThreadLock.lock(MY_THREAD_KEY)) {
 *  	try {
 * 			// do some work
 * 		}
 * 		finally {
 * 			ThreadLock.unlock(MY_THREAD_KEY);
 *  	}
 *  }
 * </pre>
 * 
 * @author Mark Smith <masmith@redhat.com>
 * @since 2013-01-04 Created
 * 
 * @author Bill C Riemers <briemers@redhat.com>
 * @since 2020-09-04 US270544 - Added comments, switched to a private set from a public map
 */
public class ThreadLock {
	/** We just us a set for our resource locking... */
	private static Set<String> resourceLocks = new Set<String>();

	/**
	 * Check to see if the lock has been obtained somewhere.
	 * 
	 * @param key
	 * @return true if locked
	 */
	public static Boolean isLocked(String key) {
		return resourceLocks.contains(key);
	}	

	/**
	 * Attempt to establish the lock.
	 * 
	 * @param key
	 * @return true if lock is obtained, false if already locked
	 */
	public static Boolean lock(String key) {
		if (islocked(key)) {
			return false;
		}
		resourceLocks.add(key);
		return true;
	}

	/**
	 * Unlock a thread.
	 * 
	 * @param key
	 * @return false if not initially locked
	 */
	public static Boolean unlock(String key) {
		if (islocked(key)) {
			resourceLocks.remove(key);
			return true;
		}
		return false;
	}
}