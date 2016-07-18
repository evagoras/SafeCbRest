component extends="v1.controllers.base" singleton
{


	// Services
	property name="orderService" inject="services.order@v1";
	// Global variables
	property name="dsn" inject="coldbox:datasource:abcamlive";

	/**
	 * @hint  Returns a list of a Orders
	 * @event ColdBox Event Model
	 * @rc    Request Collection
	 * @prc   Private Request Collection
	 */
	public any function list
	( event, rc, prc )
	{
		// Check for skip and take
		runPreListChecks( event, rc, prc );
		// Validate the request
		var orderBean = wirebox.getInstance( "beans.request.order@v1" );
		orderBean.populate( memento = rc );
		// No validation errors
		if ( orderBean.validates() )
		{
			// Order list returns a Response Bean
			var responseBean = orderService.getOrders
			(
				userCode = arguments.rc.userCode,
				months = arguments.rc.months,
				skip = arguments.rc.skip,
				take = arguments.rc.take
			);
			prc.response
				.setStatusCode( responseBean.getStatusCode() )
				.setStatusText( responseBean.getStatusText() )
				.setError( responseBean.getError() )
				.setTotalCount( responseBean.getTotalCount() )
				.setData( responseBean.getData() )
			;
		}
		// Has validation errors
		else
		{
			prc.response
				.setError( true )
				.setStatusCode( 400 )
				.setStatusText( "Bad Request" )
				.setData( orderBean.returnErrors() )
			;
		}
	}


	/**
	 * @hint Returns a single instance of an order's details
	 * @event ColdBox Event Model
	 * @rc Request Collection
	 * @prc Private Request Collection
	 */
	public any function view
	( event, rc, prc )
	{
		request.objLibrary = new cfc.common.library();
		// Defining DSN
		application.dsn = dsn.name;
		var orderDetailRequestBean = wirebox.getInstance( "beans.request.orderView@v1" );
		// populate Bean from the arguments collection
		orderDetailRequestBean.populate( memento = rc );
		if ( orderDetailRequestBean.validates() )
		{
			var responseBean = orderService.getOrderDetails
			(
				orderCode = rc.orderCode,
				userCode = rc.userCode
			);
			prc.response
				.setStatusCode( responseBean.getStatusCode() )
				.setStatusText( responseBean.getStatusText() )
				.setError( responseBean.getError() )
				.setData( responseBean.getData() )
			;
		}
		// validation errors found
		else
		{
			prc.response
				.setError( true )
				.setStatusCode( 400 )
				.setStatusText( "Bad Request" )
				.setData( orderDetailRequestBean.returnErrors() )
			;
		}
	}


}