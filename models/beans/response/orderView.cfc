component accessors=true extends="models.beans.base"
{


	property name="purchaseOrderNumber"		jsonType="string";
	property name="orderStatus"				jsonType="string";
	property name="currency"				jsonType="string";
	property name="customerNotes"			jsonType="string";
	property name="userCode"				jsonType="number";
	property name="tax"						jsonType="number";
	property name="freight"					jsonType="number";
	property name="total"					jsonType="number";

	property
		name = "shippingAddress"
		fieldtype = "one-to-one"
		cfc = "models.beans.response.orderAddressView"
	;

	property
		name = "billingAddress"
		fieldtype = "one-to-one"
		cfc = "models.beans.response.orderAddressView"
	;

	property
		name = "items"
		fieldtype = "one-to-many"
		cfc = "models.beans.response.orderItem"
	;


	function init()
	{
		super.init();
		return this;
	}


	public numeric function getTax()
	{
		return numberFormat( variables.tax, ".__" );
	}


	public numeric function getTotal()
	{
		return numberFormat( variables.total, ".__" );
	}

	public numeric function getFreight()
	{
		return numberFormat( variables.freight, ".__" );
	}


}