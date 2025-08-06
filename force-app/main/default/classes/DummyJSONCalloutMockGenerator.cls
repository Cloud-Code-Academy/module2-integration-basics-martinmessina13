@IsTest
public with sharing class DummyJSONCalloutMockGenerator implements HttpCalloutMock {
    
    // Default success payload
    public static String DUMMY_JSON_USER_PAYLOAD = '{"id": 1, "firstName":"Johnny", "lastName":"Test", "email": "test@example.com", "phone": "+123456789", "birthDate": "1990-01-01", "address": {"address": "123 Test St", "city": "Test City", "postalCode": "12345", "state": "TS", "country": "Testland"}}';

    // Properties to control the mock's behavior
    private final Integer statusCode;
    private final String status;
    private final String body;
    private final Boolean shouldThrowException;

    /**
     * Default constructor for happy path scenarios.
     * Generates a 200 OK response.
     */
    public DummyJSONCalloutMockGenerator() {
        this.statusCode = 200;
        this.status = 'OK';
        this.body = null; // Body will be determined by request method (GET/POST)
        this.shouldThrowException = false;
    }

    /**
     * Constructor for simulating specific HTTP error responses.
     * @param code The HTTP status code (e.g., 404, 500).
     * @param stat The HTTP status message (e.g., 'Not Found').
     * @param errorBody The JSON body for the error response.
     */
    public DummyJSONCalloutMockGenerator(Integer code, String stat, String errorBody) {
        this.statusCode = code;
        this.status = stat;
        this.body = errorBody;
        this.shouldThrowException = false;
    }

    /**
     * Constructor for simulating a system-level CalloutException.
     */
    public DummyJSONCalloutMockGenerator(Boolean throwEx) {
        this.statusCode = -1; // Not used
        this.status = '';     // Not used
        this.body = '';       // Not used
        this.shouldThrowException = true;
    }

    public HTTPResponse respond(HTTPRequest req) {
        // Scenario 1: Simulate a connection failure by throwing an exception
        if (this.shouldThrowException) {
            throw new System.CalloutException('Mock callout exception: Unable to reach endpoint.');
        }

        // Create the response object
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(this.statusCode);
        res.setStatus(this.status);

        // Scenario 2: Return a configured error response
        if (this.statusCode != 200) {
            res.setBody(this.body);
        } else {
            // Scenario 3: Return a default success response based on the method
            if (req.getMethod() == 'POST') {
                res.setBody('{"id": 101, "status": "success"}');
            } else {
                res.setBody(DUMMY_JSON_USER_PAYLOAD);
            }
        }
        
        return res;
    }
}