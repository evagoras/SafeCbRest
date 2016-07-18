component accessors=true extends="models.beans.base"
{


	property
		name = "userCode"
		fieldtype = "direct"
		cfc = "models.beans.request.userCode"
	;

	property name="months" jsonType="number";


	this.constraints = {
		"months" = {
			type = "integer",
			min = 1,
			required = true
		}
	};


	function init()
	{
		super.init();
		return this;
	}


}