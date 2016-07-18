component extends="v1.controllers.base" singleton
{


	// Services
	property name="userService" inject="services.user@v1";
	property name="validatorService" inject="services.validator@v1";


	/**
	 * @hint Returns a single instance of a User's details
	 * @event ColdBox Event Model
	 * @rc Request Collection
	 * @prc Private Request Collection
	 */
	public any function view
	( event, rc, prc )
	{
		// Validate the ID as a simple Integer returning a STRUCT of errors
		var IDValidationResults = validatorService.validateID
		(
			key = "userCode",
			value = arguments.rc.userCode
		);
		// There were validation errors in the returned STRUCT
		if ( IDValidationResults.count() )
		{
			prc.response
				.setError( true )
				.setStatusCode( 400 )
				.setStatusText( "Bad Request" )
				.setData( IDValidationResults )
			;
		}
		// No validation errors
		else
		{
			var responseBean = userService.getUser( userCode = arguments.rc.userCode );
			prc.response
				.setStatusCode( responseBean.getStatusCode() )
				.setStatusText( responseBean.getStatusText() )
				.setError( responseBean.getError() )
				.setData( responseBean.getData() )
			;
		}
	}


	/**
	 *	@hint Updates a User's details. It can accept a partial payload.
	 *	@event ColdBox Event Model
	 *	@rc Request Collection
	 *	@prc Private Request Collection
	 */
	public any function patch
	( event, rc, prc )
	{
		// Check for empty payloads and mismatched resource identifiers
		runPrePatchChecks( rc, prc, "userCode" );
		// User update returns a Response Bean
		var responseBean = userService.updateUser( data = rc );
		prc.response
			.setError( responseBean.getError() )
			.setStatusCode( responseBean.getStatusCode() )
			.setStatusText( responseBean.getStatusText() )
			.setData( responseBean.getData() )
		;
	}


}