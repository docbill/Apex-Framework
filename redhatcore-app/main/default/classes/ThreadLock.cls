public with sharing class ThreadLock {
	static public Map<String,Boolean> resourceLocks = new Map<String,Boolean>();

	static public Boolean islocked(String key) {
		if (resourceLocks.containsKey(key)) {
			Boolean value = resourceLocks.get(key);
			return value;
		}
		return false;
	}	

	static public Boolean lock(String key) {
		if (resourceLocks.containsKey(key)) {
			Boolean value = resourceLocks.get(key);
			if (value) {
				return false;	// already locked
			}
		}
		resourceLocks.put(key, true);
		return true;	
	}

	static public Boolean unlock(String key) {
		if (resourceLocks.containsKey(key)) {
			Boolean value = resourceLocks.get(key);
			if (value) {
				resourceLocks.put(key, false);
				return true;
			}
		}
		return false;
	}

//	public static Boolean isExecuting = false;
}