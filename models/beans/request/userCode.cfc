component accessors=true extends="models.beans.base"
{


	property name="userCode" jsonType="number";


	this.constraints = {
		"userCode" = {
			type = "integer",
			required = true,
			min = 1
		}
	};


	function init()
	{
		super.init();
		return this;
	}


}