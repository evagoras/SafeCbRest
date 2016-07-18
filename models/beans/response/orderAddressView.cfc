component accessors=true extends="models.beans.base"
{


	property name="username" 		jsonType="string";
	property name="attention" 		jsonType="string";
	property name="organisation" 	jsonType="string";
	property name="address1" 		jsonType="string";
	property name="address2" 		jsonType="string";
	property name="city" 			jsonType="string";
	property name="county" 			jsonType="string";
	property name="country2LCode" 	jsonType="string";
	property name="postcode" 		jsonType="string";
	property name="email" 			jsonType="string";
	property name="telephone" 		jsonType="string";


	function init()
	{
		super.init();
		return this;
	}


}