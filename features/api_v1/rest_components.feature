Feature: Rest Components

In order to manipulate components through an api
As a machine I should list, show, edit, and delete components

Background: I should be logged in and have sample data
	Given 3 components exist
	And an app exists with a name of "Test App"
	And a property exists with a name of "Test Property"

  ############# GET COMPONENTS: INDEX #########################################
      
  Scenario: GET a 403 Forbidden when accessing the api without a token
    Given I send and accept XML
    When I send a GET request for "/v1/components"
    Then the response should be "403"  

  Scenario: GET all (not archived or deleted) components as XML
    Given I have valid API key
    And I send and accept XML
    When I send an authorized GET request to "/v1/components"
    Then the response should be "200"
    And the XML response should be a "components" array with 3 "component" elements
    
  Scenario: GET all functional (not archived or deleted) components as JSON
    Given I have valid API key
    And I send and accept JSON
    When I send an authorized GET request to "/v1/components"
    Then the response should be "200"
    And the JSON response should be an array with 3 "component" elements
    
  ############# GET COMPONENT: SHOW ##########################################  
  
  Scenario: GET a particular component as XML
    Given I have valid API key
    And I send and accept XML
    When I send an authorized GET request to "/v1/components/1"
    Then the response should be "200"
    And the XML response should include "Component 1" within "name" element   
    
  Scenario: GET a particular component as JSON
    Given I have valid API key
    And I send and accept JSON
    When I send an authorized GET request to "/v1/components/1"
    Then the response should be "200"
    And the JSON response should include "Component 1" for "name" key   
   
  Scenario: GET a 404 not found when I try to GET a nonexistent component as XML
    Given I have valid API key
    And I send and accept XML
    When I send an authorized GET request to "/v1/components/100000888888"
    Then the response should be "404"   
    
  Scenario: GET 404 not found when I try to GET a nonexistent component as JSON
    Given I have valid API key
    And I send and accept JSON
    When I send an authorized GET request to "/v1/components/100000888888"
    Then the response should be "404"   

  ############# POST COMPONENT: CREATE ##########################################  
  
  @focus
  Scenario: POST a new component as XML
    Given I have valid API key
    And I send and accept XML
    When I send an authorized XML POST request to "/v1/components" with the following under "component":
    | name 				| app_name 		| property_name			| active	|
    | XML Component		| Test App  	| Test Property 		| t			| 
    Then the response should be "201"
    And the XML response should include "XML Component" within "name" element   
  
  @focus   
  Scenario: POST a new component as JSON
    Given I have valid API key
    And I send and accept JSON
    When I send an authorized JSON POST request to "/v1/components" with the following under "component":
    | name 				| app_name 		| property_name			| active	|
    | JSON Component	| Test App  	| Test Property 		| t			| 
    Then the response should be "201"
    And the JSON response should include "JSON Component" for "name" key  

  @focus
  Scenario: GET a 422 when POST invalid values to a new component as XML
    Given I have valid API key
    And I send and accept XML
    When I send an authorized XML PUT request to "/v1/components/1" with the following under "component":
    | name 				| app_name 		| property_name			| active	|
    | 					| Test App  	| Test Property			| t			|
    Then the response should be "422" 

  Scenario: GET a 422 when POST invalid values to a new component as JSON
    Given I have valid API key
    And I send and accept JSON
    When I send an authorized JSON PUT request to "/v1/components/1" with the following under "component":
    | name 				| app_name 		| property_name			| active	|
    | 					| Test App  	| Test Property			| t			|
    Then the response should be "422"
    
  Scenario: GET a 422 when POST data causes an application error for a new component as XML
    Given I have valid API key
    And I send and accept XML
    When I send an authorized XML PUT request to "/v1/components/1" with the following under "component":
    | name 				| BAD_FIELD_NAME	    |
    |  					| XML Hello				|
    Then the response should be "422" 
    
  Scenario: GET a 422 when POST data causes an application error for a new component as JSON
    Given I have valid API key
    And I send and accept JSON
    When I send an authorized JSON PUT request to "/v1/components/1" with the following under "component":
    | name 				| BAD_FIELD_NAME        |
    | 			 		| JSON Hello			|
    Then the response should be "422"  
    
  ############# PUT COMPONENT: UPDATE ##########################################  
  
  Scenario: PUT an update to a component as XML
    Given I have valid API key
    And I send and accept XML
    When I send an authorized XML PUT request to "/v1/components/1" with the following under "component":
    | name 				| 
    | XML Rename		| 
    Then the response should be "202"
    And the XML response should include "XML Rename" within "name" element   
   
  Scenario: PUT an update to a component as JSON
    Given I have valid API key
    And I send and accept JSON
    When I send an authorized JSON PUT request to "/v1/components/1" with the following under "component":
    | name 				| 
    | JSON Rename		| 
    Then the response should be "202"
    And the JSON response should include "JSON Rename" for "name" key   

  Scenario: GET a 422 when PUT an update with invalid values to a component as XML
    Given I have valid API key
    And I send and accept XML
    When I send an authorized XML PUT request to "/v1/components/1" with the following under "component":
    | name 				| 
    | 					| 
    Then the response should be "422" 
    
  Scenario: GET a 422 when PUT an update with invalid values to a component as JSON
    Given I have valid API key
    And I send and accept JSON
    When I send an authorized JSON PUT request to "/v1/components/1" with the following under "component":
    | name 				| 
    | 					|
    Then the response should be "422"
    
  Scenario: GET a 422 when PUT an update that causes an application error for component as XML
    Given I have valid API key
    And I send and accept XML
    When I send an authorized XML PUT request to "/v1/components/1" with the following under "component":
    | name 				| BAD_FIELD_NAME	    |
    | Test Bad Field	| XML Hello				|
    Then the response should be "422" 
    
  Scenario: GET a 422 when PUT an update that causes an application error for component as JSON
    Given I have valid API key
    And I send and accept JSON
    When I send an authorized JSON PUT request to "/v1/components/1" with the following under "component":
    | name 				| BAD_FIELD_NAME        |
    | Test Bad Field	| JSON Hello			|
    Then the response should be "422"  
        
  Scenario: GET a 404 when PUT an update to a non-existant component as XML
    Given I have valid API key
    And I send and accept XML
    When I send an authorized XML PUT request to "/v1/components/193939393" with the following under "component":
    | name 				| 
    | XML Rename		| 
    Then the response should be "404" 
   
  Scenario: GET a 404 when PUT an update to a non-existant component as  JSON
    Given I have valid API key
    And I send and accept JSON
    When I send an authorized JSON PUT request to "/v1/components/18548548" with the following under "component":
    | name 				| 
    | JSON Rename		| 
    Then the response should be "404"

  ############# DELETE COMPONENT: SOFT DESTROY #################  
  
  Scenario: DELETE a particular component as XML
    Given I have valid API key
    And I send and accept XML
    When I send an authorized DELETE request to "/v1/components/1"
    Then the response should be "202"  
    
  Scenario: DELETE a particular component as JSON
    Given I have valid API key
    And I send and accept JSON
    When I send an authorized DELETE request to "/v1/components/1"
    Then the response should be "202"   
   
  Scenario: GET a 404 not found when I try to DELETE a nonexistent component as XML
    Given I have valid API key
    And I send and accept XML
    When I send an authorized DELETE request to "/v1/components/100000888888"
    Then the response should be "404"   
    
  Scenario: GET 404 not found when I try to DELETE a nonexistent component as JSON
    Given I have valid API key
    And I send and accept JSON
    When I send an authorized DELETE request to "/v1/components/100000888888"
    Then the response should be "404"     
    
  ############# SPECIAL CASE: GET COMPONENTS WITH NO COMPONENTS #################
  
  @focus
  Scenario: get a 404 Not Found when no components exist
    Given I have valid API key
    And I send and accept XML
    And no "components" exist
    When I send an authorized GET request to "/v1/components"
    Then the response should be "404"  
    #If you want to inspect the API request and response
    #And show me the last request
    #And show me the last response
