/**
 * Utility class for handling operations related to Contact records, 
 * such as generating dummy JSON IDs and making external callouts
 * using DummyJSONCallout methods.
 * 
 * This class contains only static methods and does not maintain any instance state.
 * 
 * The class should be called from within a trigger or another Apex class that processes Contacts.
 * @author Martin Messina
 * @since 08-04-2025
 */

public with sharing class ContactTriggerHandler {
    /**
     * Populates the DummyJSON_Id__c field of each Contact in the provided list 
     * with a random number between 0 and 100 if it is not already set.
     *
     * @param contacts List of Contact records to process.
     * @param isInsert context variable that indicates whether in insert context.
     * @param isBefore context variable that indicates whether in before trigger context.
     * @return void
     */
    public static void generateDummyJSONId(List<Contact> contacts, Boolean isInsert, Boolean isBefore){
        if(isInsert && isBefore){
            for(Contact contact:contacts){
                if(contact.DummyJSON_Id__c == null){
                    contact.DummyJSON_Id__c = String.valueOf(Math.round(Math.random() * 100));
                }
            }
        }
    }

    /**
     * Calls DummyJSONCallout.getDummyJSONUserFromId for each Contact whose
     * DummyJSON_Id__c field is less than or equal to 100.
     *
     * This method is typically used to retrieve user information from an external
     * DummyJSON API for contacts with valid DummyJSON IDs (0-100).
     *
     * @param contacts List of Contact records to process.
     * @param isInsert context variable that indicates whether in insert context.
     * @param isBefore context variable that indicates whether in before trigger context.
     * @return void
     */
    public static void callGetDummyJSONUserFromId(List<Contact> contacts, Boolean isInsert, Boolean isBefore){
        if(isInsert && !isBefore && !System.isFuture()){ // Avoiding re-running trigger without the use of static variables
            for(Contact contact:contacts){
                // Only process contacts where DummyJSON_Id__c is less than or equal to 100
                if(Integer.valueOf(contact.DummyJSON_Id__c) < 101){
                    DummyJSONCallout.getDummyJSONUserFromId(contact.DummyJSON_Id__c);
                }
            }
        }
    }

    /**
     * Calls DummyJSONCallout.postCreateDummyJSONUser for each Contact whose 
     * DummyJSON_Id__c field is greater than 100.
     *
     * This method is typically used to create new user records in the external 
     * DummyJSON API for contacts without a valid DummyJSON ID in the 0-100 range.
     *
     * @param contacts List of Contact records to process.
     * @param isUpdate context variable that indicates whether in update context.
     * @return void
     */
    public static void callPostCreateDummyJSONUser(List<Contact> contacts, Boolean isUpdate){
        if(isUpdate){
            for(Contact contact:contacts){
                // Only process contacts where DummyJSON_Id__c is greater than 100
                if(Integer.valueOf(contact.DummyJSON_Id__c) > 100){
                    DummyJSONCallout.postCreateDummyJSONUser(contact.Id);
                }
            }
        }
    }
}