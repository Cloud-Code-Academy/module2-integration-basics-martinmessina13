/*
 * Update the ContactTrigger.trigger to do a callout to the DummyJSONCallout class to retrieve/send user data from the Dummy JSON API.
 * Implement the DummyJSONCallout class to handle the callouts to the Dummy JSON API.
 */
@IsTest
public with sharing class DummyJSONCalloutTest {
	// This test method will test the getDummyJSONUserFromId future method with a mock HTTP response.
	@IsTest
	static void testGetDummyJSONUserFromId() {
		// Create contact
		Contact cont = new Contact(FirstName = 'Test', LastName = 'User', DummyJSON_Id__c = '1');
		insert cont;
		// Register the mock callout class
		Test.setMock(HttpCalloutMock.class, new DummyJSONCalloutMockGenerator());

		// As this is a future method, we need to enclose it in Test.startTest() and Test.stopTest() to ensure it's executed in the test context.
		Test.startTest();
		DummyJSONCallout.getDummyJSONUserFromIds(new Set<String>{'1'}); // Call the method with an example userId
		Test.stopTest();

		// After the stopTest, the future method will have run. Now we can check if the contact was created correctly.
		cont = [
			SELECT Email, Phone, Birthdate, MailingStreet, MailingCity, MailingPostalCode, MailingState, MailingCountry
			FROM Contact
			WHERE DummyJSON_Id__c = '1'
		];

		// Assert statements to ensure that the values in the created contact match what was in our mock response.
		System.assertEquals('test@example.com', cont.Email, 'Email does not match your value: ' + cont.Email);
		System.assertEquals('+123456789', cont.Phone, 'Phone does not match your value: ' + cont.Phone);
		System.assertEquals(
			Date.valueOf('1990-01-01'),
			cont.Birthdate,
			'Birthdate does not match your value: ' + cont.Birthdate
		);
		System.assertEquals(
			'123 Test St',
			cont.MailingStreet,
			'MailingStreet does not match your value: ' + cont.MailingStreet
		);
		System.assertEquals(
			'Test City',
			cont.MailingCity,
			'MailingCity does not match your value: ' + cont.MailingCity
		);
		System.assertEquals(
			'12345',
			cont.MailingPostalCode,
			'MailingPostalCode does not match your value: ' + cont.MailingPostalCode
		);
		System.assertEquals('TS', cont.MailingState, 'MailingState does not match your value: ' + cont.MailingState);
		System.assertEquals(
			'Testland',
			cont.MailingCountry,
			'MailingCountry does not match your value: ' + cont.MailingCountry
		);
	}

	@isTest
	static void testPostCreateDummyJSONUser() {
		// Create a dummy contact to simulate the scenario
		Contact testContact = new Contact(
			FirstName = 'John',
			LastName = 'Doe',
			Email = 'john.doe@example.com',
			Phone = '+123456789'
		);
		insert testContact;

		// Set the mock callout class
		Test.setMock(HttpCalloutMock.class, new DummyJSONCalloutMockGenerator());

		// As this is a future method, we need to enclose it in Test.startTest() and Test.stopTest() to ensure it's executed in the test context.
		Test.startTest();
		DummyJSONCallout.postCreateDummyJSONUsers(new Set<String>{testContact.Id});
		Test.stopTest();

		// Retrieve the updated contact to verify the changes
		Contact updatedContact = [SELECT DummyJSON_Last_Updated__c FROM Contact WHERE Id = :testContact.Id];

		// Ensure that the DummyJSON_Last_Updated__c field was updated
		System.assertNotEquals(
			null,
			updatedContact.DummyJSON_Last_Updated__c,
			'The DummyJSON_Last_Updated__c field should have been updated.'
		);
	}

	@isTest
	static void testGenerateDummyJsonUserPayload() {
		// Prepare test data
		Contact testContact = new Contact(
			FirstName = 'John',
			LastName = 'Doe',
			Email = 'john.doe@example.com',
			Phone = '1234567890',
			DummyJSON_Id__c = '101'
		);
		insert testContact;

		// Call the method
		String payload = DummyJSONCallout.generateDummyJsonUserPayload(testContact);

		// Parse the generated JSON
		Map<String, Object> payloadMap = (Map<String, Object>) JSON.deserializeUntyped(payload);

		// Assertions to check if the payload contains the right data
		System.assertEquals(testContact.Id, payloadMap.get('salesforceId'), 'Id does not match.');
		System.assertEquals('John', payloadMap.get('firstName'), 'FirstName does not match.');
		System.assertEquals('Doe', payloadMap.get('lastName'), 'LastName does not match.');
		System.assertEquals('john.doe@example.com', payloadMap.get('email'), 'Email does not match.');
		System.assertEquals('1234567890', payloadMap.get('phone'), 'Phone does not match.');
	}

	@isTest
	static void testCreateContactFromJson() {
		// JSON string that represents the response data
		String jsonResponse = DummyJSONCalloutMockGenerator.DUMMY_JSON_USER_PAYLOAD;

		// Call the method
		Contact cont = DummyJSONCallout.createContactFromJson(jsonResponse);

		// Assertions to check if the Contact object was populated correctly
		System.assertEquals('test@example.com', cont.Email, 'Email does not match.');
		System.assertEquals('+123456789', cont.Phone, 'Phone does not match.');
		System.assertEquals(Date.valueOf('1990-01-01'), cont.Birthdate, 'Birthdate does not match.');
		System.assertEquals('123 Test St', cont.MailingStreet, 'MailingStreet does not match.');
		System.assertEquals('Test City', cont.MailingCity, 'MailingCity does not match.');
		System.assertEquals('12345', cont.MailingPostalCode, 'MailingPostalCode does not match.');
		System.assertEquals('TS', cont.MailingState, 'MailingState does not match.');
		System.assertEquals('Testland', cont.MailingCountry, 'MailingCountry does not match.');
	}

	@IsTest
	static void testContactInsert() {
		//Create 100 contact
		List<Contact> contacts = new List<Contact>();
		for (Integer i = 0; i < 1; i++) {
			contacts.add(new Contact(FirstName = 'Test', LastName = 'User' + i));
		}

		// Register the mock callout class
		Test.setMock(HttpCalloutMock.class, new DummyJSONCalloutMockGenerator());

		// As this is a future method, we need to enclose it in Test.startTest() and Test.stopTest() to ensure it's executed in the test context.
		Test.startTest();
		Database.DMLOptions dml = new Database.DMLOptions();
		dml.DuplicateRuleHeader.allowSave = true;
		dml.DuplicateRuleHeader.runAsCurrentUser = true;
		Database.SaveResult[] sr = Database.insert(contacts, dml);
		Test.stopTest();

		// After the stopTest, the future method will have run. Now we can check if the contact was created correctly.
		contacts = [
			SELECT
				DummyJSON_Id__c,
				Email,
				Phone,
				Birthdate,
				MailingStreet,
				MailingCity,
				MailingPostalCode,
				MailingState,
				MailingCountry
			FROM Contact
			WHERE Id IN :contacts AND DummyJSON_Id__c != NULL
		];
		Assert.isTrue(!contacts.isEmpty(), 'No contacts were created');

		for (Contact cont : contacts) {
			Assert.isTrue(cont.DummyJSON_Id__c.isNumeric(), 'DummyJSON_Id is not numeric string');
			Integer dummyJSONId = Integer.valueOf(cont.DummyJSON_Id__c);
			Assert.isTrue(dummyJSONId >= 0 && dummyJSONId <= 100, 'Expected range of DummyJSON_Id is [0-100]');
		}
	}

	@IsTest
	static void testPostCreateDummyJSONUserAfterInsert() {
		// Create and insert a test contact
		Contact cont = new Contact(
			FirstName = 'Test',
			LastName = 'User',
			Email = 'test@example.com',
			Phone = '+123456789',
			DummyJSON_Id__c = '105'
		);
		insert cont;

		// Update the DummyJSON_Id__c to simulate the scenario where a contact gets a DummyJSON ID
		cont.DummyJSON_Id__c = '1';
		update cont;

		// Register the mock callout class
		Test.setMock(HttpCalloutMock.class, new DummyJSONCalloutMockGenerator());

		// Execute the future method within test context
		Test.startTest();
		DummyJSONCallout.postCreateDummyJSONUsers(new Set<String>{cont.Id});
		Test.stopTest();

		// Query the contact after the callout
		Contact updatedContact = [
			SELECT DummyJSON_Last_Updated__c, DummyJSON_Id__c
			FROM Contact
			WHERE Id = :cont.Id
		];

		// Verify the contact was updated correctly
		System.assertNotEquals(
			null,
			updatedContact.DummyJSON_Last_Updated__c,
			'DummyJSON_Last_Updated__c should be set after successful callout'
		);
		System.assertEquals('1', updatedContact.DummyJSON_Id__c, 'DummyJSON_Id__c should remain unchanged');
	}

	/*
	================================================================================
	|                  EXCEPTION HANDLING AND SAD PATH TESTS                       |
	================================================================================
	| The following tests use the enhanced DummyJSONCalloutMockGenerator to        |
	| validate the error handling paths of the DummyJSONCallout class.             |
	--------------------------------------------------------------------------------
	*/

	@IsTest
	static void testGetDummyUserHttpError() {
		// Test Goal: Verify that a non-200 HTTP response in getDummyJSONUserFromIds
		// is caught and logged correctly.
		Test.startTest();

		// Configure the mock to return an HTTP 404 Not Found error
		HttpCalloutMock errorMock = new DummyJSONCalloutMockGenerator(404, 'Not Found', '{"message":"User not found"}');
		Test.setMock(HttpCalloutMock.class, errorMock);

		// Call the method that performs the callout
		DummyJSONCallout.getDummyJSONUserFromIds(new Set<String>{'999'});

		Test.stopTest();

		// Verify that a log record was created due to the error
		List<Custom_Log__c> logs = [SELECT Message__c, Log_Level__c FROM Custom_Log__c];
		System.assertEquals(1, logs.size(), 'An error log should have been created.');
		System.assertEquals('Error', logs[0].Log_Level__c, 'Log level should be Error.');
		System.assert(logs[0].Message__c.contains('Not Found'), 'Log message should contain the HTTP status.');
	}

	@IsTest
	static void testGetDummyUserCalloutException() {
		// Test Goal: Verify that a system CalloutException is caught and logged.
		Test.startTest();

		// Configure the mock to throw a CalloutException
		HttpCalloutMock exceptionMock = new DummyJSONCalloutMockGenerator(true);
		Test.setMock(HttpCalloutMock.class, exceptionMock);

		// Call the method that performs the callout
		DummyJSONCallout.getDummyJSONUserFromIds(new Set<String>{'1'});

		Test.stopTest();

		// Verify that the exception was caught and logged
		List<Custom_Log__c> logs = [SELECT Message__c, Log_Level__c FROM Custom_Log__c];
		System.assertEquals(1, logs.size(), 'An error log should have been created for the CalloutException.');
		System.assert(logs[0].Message__c.contains('Mock callout exception'), 'Log message should contain the exception details.');
	}

	@IsTest
	static void testPostDummyUserHttpError() {
		// Test Goal: Verify that a non-2xx HTTP response in postCreateDummyJSONUsers
		// is caught and logged correctly.
		Contact testContact = new Contact(FirstName='Test', LastName='User', Email='test@test.com', Phone='111');
		insert testContact;

		Test.startTest();

		// Configure the mock to return an HTTP 500 Internal Server Error
		HttpCalloutMock errorMock = new DummyJSONCalloutMockGenerator(500, 'Server Error', '{"message":"Server exploded"}');
		Test.setMock(HttpCalloutMock.class, errorMock);

		// Call the method that performs the callout
		DummyJSONCallout.postCreateDummyJSONUsers(new Set<String>{testContact.Id});

		Test.stopTest();

		// Verify that a log record was created
		List<Custom_Log__c> logs = [SELECT Message__c FROM Custom_Log__c];
		System.assertEquals(2, logs.size(), 'Two error logs should have been created.');
		System.assert(logs[0].Message__c.contains('Server Error'), 'Log message should contain the HTTP status.');

		// Verify the contact was not updated on failure
		Contact resultContact = [SELECT DummyJSON_Last_Updated__c FROM Contact WHERE Id = :testContact.Id];
		System.assertEquals(null, resultContact.DummyJSON_Last_Updated__c, 'Last updated date should not be set on failure.');
	}

	/**
	 * @description Tests that a DummyJSONException is thrown when a Contact is missing an email.
	 */
	@IsTest
	static void testGeneratePayloadThrowsExceptionForMissingEmail() {
		// Arrange: Create a contact with a name and phone, but no email.
		Contact contactWithoutEmail = new Contact(
			FirstName = 'No',
			LastName = 'Email',
			Phone = '555-5678'
		);
		insert contactWithoutEmail;

		// Act & Assert
		try {
			DummyJSONCallout.generateDummyJsonUserPayload(contactWithoutEmail);
			System.assert(false, 'Expected a DummyJSONException for a contact with no email.');
		} catch (DummyJSONCallout.DummyJSONException e) {
			// Assert that the correct exception was caught.
			System.assertEquals('Contact does not have an associated email address', e.getMessage(), 'Incorrect exception message for missing email.');
		}
	}

	/**
	 * @description Tests that a DummyJSONException is thrown when a Contact is missing a phone number.
	 */
	@IsTest
	static void testGeneratePayloadThrowsExceptionForMissingPhone() {
		// Arrange: Create a contact with a name and email, but no phone.
		Contact contactWithoutPhone = new Contact(
			FirstName = 'No',
			LastName = 'Phone',
			Email = 'nophone@example.com'
		);
		insert contactWithoutPhone;

		// Act & Assert
		try {
			DummyJSONCallout.generateDummyJsonUserPayload(contactWithoutPhone);
			System.assert(false, 'Expected a DummyJSONException for a contact with no phone.');
		} catch (DummyJSONCallout.DummyJSONException e) {
			// Assert that the correct exception was caught.
			System.assertEquals('Contact does not have a phone number', e.getMessage(), 'Incorrect exception message for missing phone.');
		}
	}
}