# SafeCbRest
Safely populates, validates and serializes nested relationships using the ColdBox framework

The examples show some use cases. The `/models/beans/request` folder includes representations of requests coming in, while the `/models/beans/response` folder are the JSON responses going out to the client.

##PATCH scenario
Request comes in with a JSON payload including the fields to update. Our Controller could then look like:
```javascript
var requestBean = wirebox.getInstance( "beans.request.order@v1" );
requestBean.populate( memento = rc );
// No validation errors
if ( orderBean.validates() )
{
  // call the service layer
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

ejdhwe
