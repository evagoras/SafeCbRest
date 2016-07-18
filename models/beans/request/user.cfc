component accessors=true extends="models.beans.base"
{


	property
		name = "userCode"
		fieldtype = "direct"
		cfc = "models.beans.request.userCode"
	;

	property name="defaultLanguage"		jsonType="string";
	property name="title"				jsonType="string";
	property name="firstName"			jsonType="string";
	property name="familyName"			jsonType="string";
	property name="email"				jsonType="string";
	property name="firstNameNative"		jsonType="string";
	property name="familyNameNative"	jsonType="string";
	property name="position"			jsonType="string";
	property name="privacy"				jsonType="number";


	this.constraints = {
		"defaultLanguage" = {
			// db is NVARCHAR(3) NULL
			size = "0..3",
			inList = "en,ja,de,it,fr,zh,es"
		},
		"title" = {
			// db is NVARCHAR(30) NULL
			size = "0..30"
		},
		// db is NVARCHAR(100) NULL
		"firstName" = {
			size = "1..100"
		},
		// db is NVARCHAR(100) NULL
		"familyName" = {
			size = "1..100"
		},
		// db is NVARCHAR(100) NULL
		"email" = {
			size = "1..100",
			optionalUdf = validateEmail
		},
		// db is NVARCHAR(100) NULL
		"firstNameNative" = {
			size = "0..100"
		},
		// db is NVARCHAR(100) NULL
		"familyNameNative" = {
			size = "0..100"
		},
		// db is NVARCHAR(250) NULL
		"position" = {
			size = "0..250",
			optionalInList = "Undergrad student,Postgrad / Grad student,Postdoc,Research Assistant,Lab Technician,Lab Manager,Head of Lab,Purchasing Agent,Scientist,Other Technologist"
		},
		// db is TINYINT NOT NULL
		"privacy" = {
			inList = "AllMarketing,ResearchAreaOnly,NoMarketing"
		}
	};


	function init()
	{
		super.init();
		return this;
	}


	/**
	 * @hint Custom validation function for the Email property
	 */
	public boolean function validateEmail
	(
		required any value,
		required any target
	)
	{
		var isValid = false;
		if ( ! isValid( "numeric", arguments.value ) && arguments.value.len() > 0 )
		{
			var strEmailRegEx = "^([-\w]+\.)*[-\w]+@([-\w]+\.)+[A-Za-z]+$";
			var strEmailRegExTag = "^[-\w ]*<([-\w]+\.)*[-\w]+@([-\w]+\.)+[A-Za-z]+>$";
			if
			(
				reFindNoCase( strEmailRegEx, arguments.value )
				||
				reFindNoCase( strEmailRegExTag, arguments.value )
			)
				isValid = true;
		}
		return isValid;
	}


	/**
	 * @hint Enum calculations for the allowed values
	 */
	public numeric function vetoGetPrivacy()
	{
		switch ( variables.privacy )
		{
			case "AllMarketing":
				return 1;
			break;
			case "ResearchAreaOnly":
				return 2;
			break;
			case "NoMarketing":
				return 3;
			break;
		}
	}


}