# SafeCbRest
Safely populates, validates and serializes nested relationships using the ColdBox framework

The examples show some use cases and are based on the REST ColdBox bootstrap. The `/models/beans/request` folder includes representations of requests coming in, while the `/models/beans/response` folder are the JSON responses going out to the client.

##PATCH scenario
Request comes in with a JSON payload including the fields to update. Our Controller could then look like:
```javascript
var requestBean = wirebox.getInstance( "beans.request.order@v1" );
requestBean.populate( memento = rc );
// No validation errors
if ( requestBean.validates() )
{
	orderQuery = orderDao.getOrderQuery( arguments.rc.orderCode );
	if ( orderQuery.recordCount == 1 )
	{
		var responseBean = wirebox.getInstance( "beans.response.order@v1" );
		responseBean.populate( memento = orderQuery );
		prc.response
			.setStatusCode( 200 )
			.setStatusText( "OK" )
			.setData(
				responseBean.serializeAs( "json" )
			)
		;
	}
}
else
{
  prc.response
		.setError( true )
		.setStatusCode( 400 )
		.setStatusText( "Bad Request" )
		.setData( requestBean.returnErrors() )
	;
}
```

##Main public functions
###`populate()`
Populate will step through each property of the bean and do just that. For the properties that are structures, it will init() the other class, populate it and then add the whole class to the property - just like ORM. Similar thing with arrays - it will create an array of objects.
Examples:
```javascript
property
	name = "userCode"
	fieldtype = "direct"
	cfc = "models.beans.request.userCode"
;
property
	name = "shippingAddress"
	fieldtype = "one-to-one"
	cfc = "models.beans.response.orderAddressView"
;
property
	name = "items"
	fieldtype = "one-to-many"
	cfc = "models.beans.response.orderItem"
;
```
###`validate()`
Validate will use the cbValidator module and it will check the constraints in each Bean. For a structure it will return a key in the form of "basekey.nestedkey" and for arrays "basekey[1].nestedkey".
Example of a `400 Bad Request` returned to the client with the validation errors as JSON:
```javascript
{
	"location": [
		{
			"message": "The 'location' value does not match the regular expression: [A-Z]{2}",
			"data": "[A-Z]{2}",
			"type": "regex"
		},
		{
			"message": "The 'location' value is required",
			"data": true,
			"type": "required"
		}
	],
	"lines[1].lineVAT": [
		{
			"message": "The 'lineVAT' value is required",
			"data": true,
			"type": "required"
		}
	],
	"lines[1].lotNo": [
		{
			"message": "The 'lotNo' value is required",
			"data": true,
			"type": "required"
		}
	]
}
```
###`serializeAs()`
Serialize will use the `chr(2)` prepend trick to maintain type safety when populating a class and then serializing out to JSON (it will be removed after the structure is changed to a JSON string). You can take a populated Bean with all its relationships and the functions will take take care of looping through the relationships and properly serialize them as `JSON` or `XML`.

There are 4 JSON types that the method respects:

1. boolean
2. numeric
3. string
4. date

Example:
```javascript
property name="orderCode"     jsonType="number";
property name="accountNumber" jsonType="string";
property name="isOpen"        jsonType="boolean" column="bit_open";
property name="dateIssued"    jsonType="date";
```

The `column` attribute works similar to the ORM attribute, in that you can pass a key in the Bean named something and populate another key. In the example above, you can pass a key called `bit_open` and it will serialize as `isOpen`.
