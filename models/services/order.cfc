component singleton
{


	// DAOs
	property name="orderDao" inject="daos.order@v1";
	// Framework Services
	property name="wirebox" inject="wirebox";
	// Other Services
	property name="utils" inject="utils";


	public any function init()
	{
		return this;
	}


	/**
	 * @hint Returns the Details of a Collection of Resources
	 * @data The payload data
	 */
	public any function getOrders
	(
		required numeric userCode,
		required numeric months,
		required numeric skip,
		required numeric take
	)
	{
		var responseBean = wirebox.getInstance( "beans.response@v1" );
		var orderCollection = [];
		var orders = orderDao.getOrdersByUserCode
		(
			userCode = arguments.userCode,
			months = arguments.months,
			skip = arguments.skip,
			take = arguments.take
		);
		var responseBean = wirebox.getInstance( "beans.response@v1" );
		if ( orders.recordCount == 0 )
		{
			responseBean
				.setStatusCode( 204 )
				.setStatusText( "No Content" )
			;
		}
		else
		{
			var totalCount = orders.totalCount[ 1 ];
			for ( var order in orders )
			{
				var orderResponseBean = wirebox.getInstance( "beans.response.order@v1" );
				// convert dates from the db which are assumed to be UK locale (GMT/BST) to UTC
				if ( order.dateDispatched != "" )
					order.dateDispatched = utils.convertUKDateTimeToUTC( order.dateDispatched )
				;
				if ( order.datePlaced != "" )
					order.datePlaced = utils.convertUKDateTimeToUTC( order.datePlaced )
				;
				orderResponseBean.populate( order );
				orderCollection.append( orderResponseBean );
			}
			responseBean
				.setStatusCode( 200 )
				.setStatusText( "OK" )
				.setTotalCount( totalCount )
				.setData( orderCollection )
			;
		}
		return responseBean;
	}


	/**
	 * @hint Returns the order details of a Single Resource
	 * @orderCode The Order ID
	 * @userCode The user ID of the order
	 */
	public any function getOrderDetails
	(
		required numeric orderCode,
		required numeric userCode
	)
	{
		var responseBean = wirebox.getInstance( "beans.response@v1" );
		// Order Details Response Bean
		var orderDetailResponseBean = wirebox.getInstance( "beans.response.orderView@v1" );
		var orderDetailAsQuery = orderDao.getOrderDetails
		(
			orderCode = arguments.orderCode,
			userCode = arguments.userCode
		);
		// If a record for order details is found
		if ( orderDetailAsQuery.recordCount > 0 )
		{
			var orderDetails = {
				"purchaseOrderNumber" = orderDetailAsQuery[ "purchaseOrderNumber" ][ 1 ],
				"orderStatus" = orderDetailAsQuery[ "orderStatus" ][ 1 ],
				"currency" = orderDetailAsQuery[ "currency" ][ 1 ],
				"customerNotes" = orderDetailAsQuery[ "customerNotes" ][ 1 ],
				"userCode" = orderDetailAsQuery[ "userCode" ][ 1 ],
				"freight" = orderDetailAsQuery[ "freight" ][ 1 ],
				"shippingAddress" = {
					"username" = orderDetailAsQuery[ "shipping_address_username" ][ 1 ],
					"attention" = orderDetailAsQuery[ "shipping_address_attention" ][ 1 ],
					"organisation" = orderDetailAsQuery[ "shipping_address_organisation" ][ 1 ],
					"address1" = orderDetailAsQuery[ "shipping_address_address1" ][ 1 ],
					"address2" = orderDetailAsQuery[ "shipping_address_address2" ][ 1 ],
					"city" = orderDetailAsQuery[ "shipping_address_city" ][ 1 ],
					"county" = orderDetailAsQuery[ "shipping_address_county" ][ 1 ],
					"country2LCode" = orderDetailAsQuery[ "shipping_address_country2LCode" ][ 1 ],
					"postCode" = orderDetailAsQuery[ "shipping_address_postCode" ][ 1 ],
					"email" = orderDetailAsQuery[ "shipping_address_email" ][ 1 ],
					"telephone" = orderDetailAsQuery[ "shipping_address_telephone" ][ 1 ]
				},
				"billingAddress" = {
					"username" = orderDetailAsQuery[ "billing_address_username" ][ 1 ],
					"attention" = orderDetailAsQuery[ "billing_address_attention" ][ 1 ],
					"organisation" = orderDetailAsQuery[ "billing_address_organisation" ][ 1 ],
					"address1" = orderDetailAsQuery[ "billing_address_address1" ][ 1 ],
					"address2" = orderDetailAsQuery[ "billing_address_address2" ][ 1 ],
					"city" = orderDetailAsQuery[ "billing_address_city" ][ 1 ],
					"county" = orderDetailAsQuery[ "billing_address_county" ][ 1 ],
					"country2LCode" = orderDetailAsQuery[ "billing_address_country2LCode" ][ 1 ],
					"postCode" = orderDetailAsQuery[ "billing_address_postCode" ][ 1 ],
					"email" = orderDetailAsQuery[ "billing_address_email" ][ 1 ],
					"telephone" = orderDetailAsQuery[ "billing_address_telephone" ][ 1 ]
				},
				"items" = []
			};

			var chinaTaxRate = "";
			var isChina = ( orderDetails.shippingAddress.country2LCode == "CN" );
			if ( isChina )
				chinaTaxRate = orderDao.getTaxRate("CN")
			;
			var totalCost = 0;
			var totalDiscount = 0;
			for ( var row in orderDetailAsQuery )
			{
				var totalUnitsCost =  row.item_total_units_cost;
				var unitCost = row.item_unit_cost;
				var totalUnitsDiscount = row.item_total_units_discount;
				if ( isChina )
				{
					totalUnitsCost = ceiling( totalUnitsCost * chinaTaxRate );
					unitCost = ceiling( unitCost * chinaTaxRate );
					totalUnitsDiscount = ceiling( totalUnitsDiscount * chinaTaxRate );
				}
				var itemInfo = {
					"size" = row.item_size,
					"quantity" = row.item_quantity,
					"unit" = row.item_unit,
					"productCode" = row.item_product_code,
					"description" = row.item_description,
					"unitCost" = unitCost,
					"totalUnitsCost" = totalUnitsCost,
					"totalUnitsDiscount" = totalUnitsDiscount,
					"status" = row.item_status,
					"purchaseOrderNumber" = row.item_purchase_order_number,
					"id" = row.item_id
				};
				totalCost = totalCost + row.item_total_units_cost;
				totalDiscount = totalDiscount + row.item_total_units_discount;
				orderDetails.items.append(	itemInfo );
			}
			var taxRate = orderDetailAsQuery[ "taxRate" ][ 1 ];
			orderDetails.tax = taxRate * 0.01 * ( ( totalCost + orderDetails.freight ) - totalDiscount );
			orderDetails.total = orderDetails.tax + ( ( totalCost + orderDetails.freight ) - totalDiscount );
			// populate the response Bean
			orderDetailResponseBean.populate( memento = orderDetails );
			responseBean
				.setStatusCode( 200 )
				.setStatusText( "OK" )
				.setData( orderDetailResponseBean )
			;
		}
		else
		{
			throw
			(
				type = "ResourceNotFoundException",
				message = "No such order exists.",
				detail = "Order with orderCode #arguments.orderCode# and userCode #arguments.userCode# not found."
			);
		}
		return responseBean;
	}


}