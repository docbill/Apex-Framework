/**
 * Test class for Metadata Values Helper
 * 
 * @version 2020-08-27
 * @author Bill C Riemers <briemers@redhat.com>
 * @since 2020-08-27 US268903 - Created
 */
@IsTest
private class Metadata_Values_HelperTest {
    static Metadata_Values_Helper helper = new Metadata_Values_Helper('TEST');

    @IsTest
    static void stringValuesTest() {
        System.assertEquals('Active Value 1',helper.stringMap.get('ACTIVE_KEY1'));
        System.assertEquals('Active Value 2',helper.stringMap.get('ACTIVE_KEY2'));
        System.assertEquals(null,helper.stringMap.get('INACTIVE_KEY1'));
        System.assertEquals(null,helper.stringMap.get('INACTIVE_KEY2'));
        System.assertEquals(null,helper.stringMap.get('Dummy'));
        System.assertEquals(null,helper.stringMap.get(null));
        System.assertEquals(2,helper.stringMap.size());
    }

    @IsTest
    static void decimal2ValuesTest() {
        System.assertEquals(1.0,helper.decimal2Map.get('ACTIVE_KEY1'));
        System.assertEquals(2.0,helper.decimal2Map.get('ACTIVE_KEY2'));
        System.assertEquals(null,helper.decimal2Map.get('INACTIVE_KEY1'));
        System.assertEquals(null,helper.decimal2Map.get('INACTIVE_KEY2'));
        System.assertEquals(null,helper.decimal2Map.get('Dummy'));
        System.assertEquals(null,helper.decimal2Map.get(null));
        System.assertEquals(2,helper.decimal2Map.size());
    }
}