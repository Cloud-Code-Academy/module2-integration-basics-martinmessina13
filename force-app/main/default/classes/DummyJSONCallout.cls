/*
 * DummyJSONCallout Class Description:
 * 
 * This class, DummyJSONCallout, facilitates HTTP callouts to an external system (presumably 'DummyJsonUser' in this context) 
 * to either fetch or send user information based on a given identifier. The class supports both GET (to fetch data) 
 * and POST (to send data) operations.
 * 
 * Overview of HTTP Callouts:
 * 
 * HTTP callouts are a way for Salesforce to communicate with external systems using HTTP protocols. Through HTTP callouts, 
 * you can invoke external web services, collect data from them, or send data for further processing. Apex provides 
 * classes that enable you to both send and receive HTTP data. The primary classes for this are `HttpRequest`, which 
 * represents the request you're sending, and `HttpResponse`, which represents the response you receive.
 * 
 * Best Practices:
 * 1. Handle Exceptions: Always handle exceptions that might be thrown, to ensure your code doesn't break unexpectedly.
 * 2. Named Credentials: Use Named Credentials to store endpoint URLs and authentication details securely.
 * 3. Test Callouts: Use mock classes and interfaces to test HTTP callouts without making actual callouts.
 * 
 * For more detailed information on HTTP callouts in Apex, refer to the official Salesforce documentation: 
 * https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_classes_restful_http_httprequest.htm
 */

public with sharing class DummyJSONCallout {

	private static final String BASE_URL = 'callout:DummyJsonUser';

	/* 
	 * Question 1
     * Fetches user information from an external system https://dummyjson.com/user/{id} ('DummyJsonUser') based on the provided dummy user ID. 
     * If the callout is successful and returns an HTTP status of 200, the method will update a contact based on the DummyJSON_Id__c with the data returned from the external system.
	 * Use the createContactFromJson method to parse the JSON response and create a Salesforce Contact object.
     * Documentation: https://dummyjson.com/docs/users
	 * This callout method should work in triggers
	 * 
     * @param dummyUserIds The IDs of the users in the external system to fetch data for.
     */
	@future(callout=true)
	public static void getDummyJSONUserFromIds(Set<String> dummyUserIds) { // Using sets to avoid potential duplicates
		try{
			List<Contact> contacts = new List<Contact>();
			for(String dummyUserId:dummyUserIds){
				// Create HTTP request to send.
				HttpRequest request = new HttpRequest();
				// Set the endpoint URL. Use direct URL or for best practices use Named Credential.
				request.setEndpoint(BASE_URL + '/' + dummyUserId);
				// Set the HTTP method to GET.
				request.setMethod('GET');
				// Send the HTTP request and get the response.
				Http http = new Http();
				HttpResponse response = http.send(request);
				// If the HTTP response code is successful, parse the JSON response and update the contact.
				if(response.getStatusCode() == 200){
					Contact contact = createContactFromJson(response.getBody());
					// Validate CRUS permission
					if(isContactUpserteable()){
						contacts.add(contact);
					}
				}
				else{
					throw new DummyJSONException(response.getStatus());
				}
			}
			upsert as user contacts DummyJSON_Id__c; //insert/update from the JSON response using the external id (dummyUserId)
		}
		catch(Exception e){
			// Logging errors to log object
			Custom_Log__c log = new Custom_Log__c();
			log.Message__c = e.getMessage();
			log.Log_Level__c = 'Error';
			log.Stack_Trace__c = e.getStackTraceString();
			if(Schema.SObjectType.Custom_Log__c.isCreateable()){
				insert as user log;
			}
		}
	}

	/* 
	 * Question 2
     * Transforms a JSON response from the external system https://dummyjson.com/users into a Salesforce Contact object.
     * The method parses the JSON string to extract user details and map them to a Salesforce Contact object.
     * The contact fields populated from the JSON include Email, Phone, Birthdate, and various address-related fields.
     * The method is primarily designed to work in conjunction with callouts that fetch user details from the external system. 
	 * 
	 * Fields from JSON used to populate Salesforce Contact
	 * Fields: Email, Phone, Birthdate, MailingStreet, MailingCity, MailingPostalCode, MailingState, MailingCountry
	 * 
     * Documentation: https://dummyjson.com/docs/users
     * 
     * @param String jsonResponse The JSON string from the external system that contains user details.
     * @return Contact The Salesforce Contact object populated with details from the JSON string.
     */
	@TestVisible // Allows test class to see this method. Since it is private, it would not be visible otherwise.
	private static Contact createContactFromJson(String jsonResponse) {
		// Deserialize the JSON string into map of primitive data types.
		Map<String, Object> contactResponse = (Map<String, Object>)JSON.deserializeUntyped(jsonResponse);

		// Create a new contact from the JSON response.
		Contact contact = new Contact();

		// Set the contact fields from the JSON response.
		contact.FirstName = (String)contactResponse.get('firstName');
		contact.LastName = (String)contactResponse.get('lastName');

		contact.FirstName = contact.FirstName != null ? contact.FirstName : 'Unknown'; // Required field
		contact.LastName = contact.LastName != null ? contact.LastName : 'Unknown'; // Required field

		contact.Email = (String)contactResponse.get('email');
		contact.Phone = (String)contactResponse.get('phone');
		contact.Birthdate = Date.valueOf((String)contactResponse.get('birthDate'));
		contact.DummyJSON_Id__c = String.valueOf((Integer)contactResponse.get('id')); // casting to String
		
		// Deserialize the address from the JSON response.
		Map<String, Object> address = (Map<String, Object>)contactResponse.get('address'); 

		// Set the address fields on the contact.
		contact.MailingStreet = (String)address.get('address');
		contact.MailingCity = (String)address.get('city');
		contact.MailingPostalCode = (String)address.get('postalCode');
		contact.MailingState = (String)address.get('state');
		contact.MailingCountry = (String)address.get('country');

		return contact;
	}

	/* 
	 * Question 3
     * Sends Contact information to an external system https://dummyjson.com/users/add ('DummyJsonUser') to create or update a user based on the provided Salesforce Contact ID.
     * The method prepares a JSON payload with the contact's information and sends it to the 'DummyJsonUser' add endpoint.
     * If the callout is successful (HTTP status code between 200 and 299), the method updates the contact's 'DummyJSON_Last_Updated__c' field in Salesforce to the current time.
	 * Salesforce Contact should be used to generate the JSON payload
	 * Fields: Id, FirstName, LastName, Email, Phone
	 * This callout method should work in triggers
	 * 
     * Documentation: https://dummyjson.com/docs/users
     * 
     * @param contactIds The Salesforce Contact IDs used to generate the JSON payload for the external system.
     */
	
	@future(callout=true)
	public static void postCreateDummyJSONUsers(Set<String> contactIds) { // Using sets to avoid potential duplicates
		try{
			List<Contact> updatedContacts = new List<Contact>();

			List<Contact> contacts = [
				SELECT DummyJSON_Last_Updated__c 
				FROM Contact 
				WHERE Id = :contactIds 
				WITH USER_MODE
			];

			for(Contact contact:contacts){
				// Create HTTP request to send.
				HttpRequest request = new HttpRequest();
				// Set the endpoint URL. Use direct URL or for best practices use Named Credential.
				request.setEndpoint(BASE_URL + '/add');
				// Set the HTTP method to POST.
				request.setMethod('POST');
				// Set the body using generateDummyJsonUserPayload method.
				request.setBody(generateDummyJsonUserPayload(contact.Id));
				// Send the HTTP request and get the response.
				Http http = new Http();
				HttpResponse response = http.send(request);
				// If the HTTP response code is successful, update the contact.
				Integer responseStatusCode = response.getStatusCode();
				if(responseStatusCode > 199 && responseStatusCode < 300){
					contact.DummyJSON_Last_Updated__c = System.now();
					updatedContacts.add(contact);
				}
				else{
					throw new DummyJSONException(response.getStatus());
				}
			}
			if(
				Schema.SObjectType.Contact.isUpdateable() && 
				Schema.SObjectType.Contact.fields.DummyJSON_Last_Updated__c.isUpdateable()
			){
				update as user updatedContacts;
			}
		}
		catch(Exception e){
			// Logging errors to log object
			Custom_Log__c log = new Custom_Log__c();
			log.Message__c = e.getMessage();
			log.Log_Level__c = 'Error';
			log.Stack_Trace__c = e.getStackTraceString();
			if(Schema.SObjectType.Custom_Log__c.isCreateable()){
				insert as user log;
			}
		}
	}

	/*
	 * Question 4
     * Generates a JSON payload based on a Salesforce Contact's fields to be sent to an external system https://dummyjson.com/users/add for user creation or update.
     * The method queries a contact from Salesforce based on the provided contactId and maps its fields into a JSON payload.
     * The fields from Salesforce Contact that are transformed into the JSON payload include Id, FirstName, LastName, Email, and Phone.
     * The generated JSON payload can be sent to the external system for various operations like creating or updating a user.
	 * 
	 * Fields from Salesforce Contact used to generate JSON payload:
	 * Fields: Id => salesforceId, FirstName => firstName, LastName => lastName, Email => email, Phone => phone
	 * 
     * Documentation: https://dummyjson.com/docs/users
     * 
     * @param String contactId The Salesforce Contact ID used to fetch the contact's fields and generate the JSON payload.
     * @return String The JSON string payload that represents the Contact's details.
     */
	@TestVisible // Allows test class to see this method. Since it is private, it would not be visible otherwise.
	private static String generateDummyJsonUserPayload(String contactId) {
		// Query the contact to get the field values to generate the JSON payload.
		Contact contact = [ 
			SELECT Id, FirstName, LastName, Email, Phone 
			FROM Contact WHERE 
			Id = : contactId
			WITH USER_MODE
		];

		if(contact == null){
			throw new DummyJSONException('Contact not found with ID: ' + contactId);
		}

		// Create a map of the field values.
		Map<String, String> contactMap = new Map<String, String>{
			'salesforceId' => contact.Id, 
			'firstName' => contact.FirstName != null ? contact.FirstName : 'Unknown', // Make sure to check that required contacts fields have a value. Default the value to unknown if it does not exists.
			'lastName' => contact.LastName != null ? contact.LastName : 'Unknown', 
			'email' => contact.Email != null ? contact.Email : 'Unknown', 
			'phone' => contact.Phone != null ? contact.Phone : 'Unknown'
		};
		if(String.isBlank(contact.Email)){
			throw new DummyJSONException('Contact does not have an associated email address');
		}
		if(String.isBlank(contact.Phone)){
			throw new DummyJSONException('Contact does not have a phone number');
		}

		// Serialize the map into a JSON string.
		String payload = (String)JSON.serialize(contactMap);
		
		return payload;
	}

	private static Boolean isContactUpserteable(){
		return Schema.SObjectType.Contact.isCreateable() && Schema.SObjectType.Contact.isUpdateable() &&  
			Schema.SObjectType.Contact.fields.FirstName.isCreateable() && Schema.SObjectType.Contact.fields.FirstName.isUpdateable() &&
			Schema.SObjectType.Contact.fields.LastName.isCreateable() && Schema.SObjectType.Contact.fields.LastName.isUpdateable() &&
			Schema.SObjectType.Contact.fields.Email.isCreateable() && Schema.SObjectType.Contact.fields.Email.isUpdateable() &&
			Schema.SObjectType.Contact.fields.Phone.isCreateable() && Schema.SObjectType.Contact.fields.Phone.isUpdateable() &&
			Schema.SObjectType.Contact.fields.Birthdate.isCreateable() && Schema.SObjectType.Contact.fields.Birthdate.isUpdateable() &&
			Schema.SObjectType.Contact.fields.MailingStreet.isCreateable() && Schema.SObjectType.Contact.fields.MailingStreet.isUpdateable() &&
			Schema.SObjectType.Contact.fields.MailingCity.isCreateable() && Schema.SObjectType.Contact.fields.MailingCity.isUpdateable() &&
			Schema.SObjectType.Contact.fields.MailingPostalCode.isCreateable() && Schema.SObjectType.Contact.fields.MailingPostalCode.isUpdateable() &&
			Schema.SObjectType.Contact.fields.MailingState.isCreateable() && Schema.SObjectType.Contact.fields.MailingState.isUpdateable() &&
			Schema.SObjectType.Contact.fields.MailingCountry.isCreateable() && Schema.SObjectType.Contact.fields.MailingCountry.isUpdateable();
	}

	public class DummyJSONException extends Exception{}
}