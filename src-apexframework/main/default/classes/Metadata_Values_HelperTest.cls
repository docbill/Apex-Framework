// Copyright Red Hat
// SPDX-License-Identifier: GPL-3.0-only
/**
 * Test class for Metadata Values Helper
 * 
 * @version 2020-12-01
 * 
 * @author Bill C Riemers <briemers@redhat.com>
 * @since 2020-08-27 US268903 - Created
 * @since 2020-12-01 - Added test methods for boolean values
 */
@IsTest
private class Metadata_Values_HelperTest {
    static Metadata_Values_Helper helper = Metadata_Values_Helper.getMetadataValuesHelper('TEST');

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
