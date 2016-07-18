component accessors=true extends="models.beans.base"
{


	property name="size"					jsonType="number";
	property name="quantity"				jsonType="number";
	property name="unit"					jsonType="string";
	property name="productCode"				jsonType="string";
	property name="description"				jsonType="string";
	property name="unitCost"				jsonType="number";
	property name="totalUnitsCost"			jsonType="number";
	property name="totalUnitsDiscount"		jsonType="number";
	property name="status"					jsonType="string";
	property name="purchaseOrderNumber"		jsonType="string";
	property name="id"						jsonType="number";


	function init()
	{
		super.init();
		return this;
	}


}