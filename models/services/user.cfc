component singleton
{


	// DAOs
	property name="userDao" inject="daos.user@v1";
	// Framework Services
	property name="wirebox" inject="wirebox";
	// Other Services
	property name="validatorService" inject="services.validator@v1";


	public any function init()
	{
		return this;
	}


	/**
	 * @hint Updates a single user resource
	 * @rc The update payload data
	 */
	public any function updateUser
	( required struct data )
	{
		var responseBean = wirebox.getInstance( "beans.response@v1" );
		var userBean = wirebox.getInstance( "beans.request.user@v1" );
		// populate Bean from the RC collection
		userBean.populate( memento = arguments.data );
		// Use the cbvalidator CONSTRAINTS to validate against the payload
		userBean.validate();
		// validation errors found
		if ( userBean.hasErrors() )
		{
			responseBean
				.setError( true )
				.setStatusCode( 400 )
				.setStatusText( "Bad Request" )
				.setData( userBean.returnErrors() )
			;
		}
		// no validation errors
		else
		{
			// does the user exist?
			var userExists = userDao.userExists( arguments.data.userCode );
			if ( userExists )
			{
				if ( arguments.data.keyExists( "email" ) )
				{
					// Is the email being set not used by any other user?
					var isUserEmailUnique = userDao.isUserEmailUnique
					(
						userCode = arguments.data[ "userCode" ],
						email = arguments.data[ "email" ]
					);
					// The email is either a new one or already used by the user - validates
					if ( isUserEmailUnique == false )
					{
						responseBean
							.setError( true )
							.setStatusCode( 400 )
							.setStatusText( "Bad Request" )
							.setData
							(
								{
									"email" = [
										{
											"message" = "The email '#arguments.data.email#' is already in use by another user.",
											"data" = arguments.data.email,
											"type" = "unique"
										}
									]
								}
							);
					}
				}
				if ( responseBean.getStatusCode() == 200 )
				{
					// run the db update
					userDao.updateUser( bean = userBean );
					responseBean
						.setStatusCode( 204 )
						.setStatusText( "No Content" )
						.setData( "" )
					;
				}
			}
			// User was not found
			else
			{
				throw
				(
					type = "ResourceNotFoundException",
					message = "User not found.",
					detail = "User with userCode #arguments.data.userCode# not found."
				);
			}
		}
		return responseBean;
	}


	/**
	 * @hint Returns the Details of a Single Resource
	 * @userCode The user Code
	 */
	public any function getUser
	( required numeric userCode )
	{
		var responseBean = wirebox.getInstance( "beans.response@v1" );
		var userQuery = queryNew( "" );
		// User Bean
		var userResponseBean = wirebox.getInstance( "beans.response.user@v1" );
		userQuery = userDao.getUserQuery( arguments.userCode );
		// If a user was found
		if ( userQuery.recordCount == 1 )
		{
			userResponseBean.populate( memento = userQuery );
			responseBean
				.setStatusCode( 200 )
				.setStatusText( "OK" )
				.setData( userResponseBean )
			;
		}
		else
		{
			throw
			(
				type = "ResourceNotFoundException",
				message = "No such user exists.",
				detail = "User with userCode #arguments.userCode# not found."
			);
		}
		return responseBean;
	}


}