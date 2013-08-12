require 'spec_helper'

describe Soapforce::Client do
  let(:endpoint) { 'https://na15.salesforce.com' }

  describe "#operations" do
    it "should return list of operations from the wsdl" do
      subject.operations.should be_a(Array)
      subject.operations.should include(:login, :logout, :query, :create)
    end
  end

  describe "#login" do
    it "authenticates with username and password_and_token" do

      body = "<tns:login><tns:username>testing</tns:username><tns:password>password_and_token</tns:password></tns:login>"
      stub = stub_login_request({with_body: body})
      stub.to_return(:status => 200, :body => fixture("login_response")) #, :headers => {})

      subject.login(username: 'testing', password: 'password_and_token')
    end

    it "authenticates with session_id and instance_url" do

      body = "<tns:getUserInfo></tns:getUserInfo>"
      stub = stub_login_request({
        server_url: 'https://na15.salesforce.com',
        headers: {session_id: 'abcde12345'},
        with_body: body}
        )
      stub.to_return(:status => 200, :body => fixture("get_user_info_response"))

      subject.login(session_id: 'abcde12345', server_url: 'https://na15.salesforce.com')
      
    end

    it "should raise arugment error when no parameters are passed" do
      expect { subject.login(session_id: 'something') }.to raise_error(ArgumentError)
    end
  end

  describe "#descibeSObject" do

    it "supports single sobject name" do

      body = "<tns:describeSObject><tns:sObjectType>Opportunity</tns:sObjectType></tns:describeSObject>"
      stub = stub_api_request(endpoint, {with_body: body, fixture: 'describe_s_object_response'})

      subject.describe("Opportunity")
    end

    it "supports array of sobject names" do

      body = "<tns:describeSObjects><tns:sObjectType>Account</tns:sObjectType><tns:sObjectType>Opportunity</tns:sObjectType></tns:describeSObjects>"
      stub = stub_api_request(endpoint, {with_body: body, fixture: 'describe_s_objects_response'})

      subject.describe(["Account", "Opportunity"])
    end
  end


  describe "query methods" do
    it "#query" do

      body = "<tns:query><tns:queryString>Select Id, Name, StageName from Opportunity</tns:queryString></tns:query>"
      stub = stub_api_request(endpoint, {with_body: body, fixture: 'query_response'})

      subject.query("Select Id, Name, StageName from Opportunity")
    end

    it "#query_all" do

      body = "<tns:queryAll><tns:queryString>Select Id, Name, StageName from Opportunity</tns:queryString></tns:queryAll>"
      stub = stub_api_request(endpoint, {with_body: body, fixture: 'query_all_response'})

      subject.query_all("Select Id, Name, StageName from Opportunity")
    end

    it "#query_more" do

      body = "<tns:queryMore><tns:queryLocator>some_locator_string</tns:queryLocator></tns:queryMore>"
      stub = stub_api_request(endpoint, {with_body: body, fixture: 'query_more_response'})

      subject.query_more("some_locator_string")
    end

  end

  describe "#search" do

    it "should return search results" do

      sosl = "FIND 'Name*' IN ALL FIELDS RETURNING Account (Id, Name), Contact, Opportunity, Lead"

      body = "<tns:search><tns:searchString>#{sosl}</tns:searchString></tns:search>"
      stub = stub_api_request(endpoint, {with_body: body, fixture: 'search_response'})

      subject.search(sosl)
    end

  end

  describe "#create" do
    it "should create new object" do

      body = "<tns:create><tns:sObjects><ins0:type>Opportunity</ins0:type><tns:Name>SOAPForce Opportunity</tns:Name><tns:CloseDate>2013-08-12</tns:CloseDate><tns:StageName>Prospecting</tns:StageName></tns:sObjects></tns:create>"
      stub = stub_api_request(endpoint, {with_body: body, fixture: 'create_response'})
      
      params = { Name: "SOAPForce Opportunity", CloseDate: Date.today, StageName: 'Prospecting' }
      subject.create("Opportunity", params)
    end
  end

  describe "#update" do
    it "should update existing object" do

      body = "<tns:update><tns:sObjects><ins0:type>Opportunity</ins0:type><ins0:Id>003ABCDE</ins0:Id><tns:Name>SOAPForce Opportunity</tns:Name><tns:CloseDate>2013-08-12</tns:CloseDate><tns:StageName>Closed Won</tns:StageName></tns:sObjects></tns:update>"
      stub = stub_api_request(endpoint, {with_body: body, fixture: 'update_response'})

      params = { Id: '003ABCDE', Name: "SOAPForce Opportunity", CloseDate: Date.today, StageName: 'Closed Won' }
      subject.update("Opportunity", params)
    end
  end

  describe "#upsert" do
    it "should insert new and update existing objects" do

      body = "<tns:upsert><tns:externalIDFieldName>External_Id__c</tns:externalIDFieldName><tns:sObjects><ins0:type>Opportunity</ins0:type><tns:Name>New Opportunity</tns:Name><tns:CloseDate>2013-08-12</tns:CloseDate><tns:StageName>Prospecting</tns:StageName></tns:sObjects><tns:sObjects><ins0:type>Opportunity</ins0:type><ins0:Id>003ABCDE</ins0:Id><tns:Name>Existing Opportunity</tns:Name><tns:CloseDate>2013-08-12</tns:CloseDate><tns:StageName>Closed Won</tns:StageName></tns:sObjects></tns:upsert>"
      stub = stub_api_request(endpoint, {with_body: body, fixture: 'upsert_response'})

      objects = [
        { Name: "New Opportunity", CloseDate: Date.today, StageName: 'Prospecting' },
        { Id: '003ABCDE', Name: "Existing Opportunity", CloseDate: Date.today, StageName: 'Closed Won' }
      ]
      subject.upsert("External_Id__c", "Opportunity", objects)
    end
  end

  describe "#delete" do
    it "should delete existing objects" do
      body = "<tns:delete><tns:ids>003ABCDE</tns:ids></tns:delete>"
      stub = stub_api_request(endpoint, {with_body: body, fixture: 'delete_response'})
      subject.delete("003ABCDE")
    end
  end

end