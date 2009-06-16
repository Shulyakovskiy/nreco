﻿<%@ Control Language="c#" AutoEventWireup="false" CodeFile="MultiselectEditor.ascx.cs" Inherits="MultiselectEditor" TargetSchema="http://schemas.microsoft.com/intellisense/ie5" %>
<%@ Register TagPrefix="Dalc" Namespace="NI.Data.Dalc.Web" assembly="NI.Data.Dalc" %>
<NReco:ListBox id="multiselect"
	class="multiselect"
	style="display:none"
	width="450"
	height="120"
	runat="server"
	DataTextField="<%# TextFieldName %>"
	DataValueField="<%# ValueFieldName %>"
	SelectionMode="multiple"
	SelectedValues='<%# GetSelectedIds() %>'
	DataSource='<%# GetDataSource() %>'
	PreserveOrder='<%# Sortable %>'/>

<script language="javascript">
jQuery(function(){
	jQuery('#<%=multiselect.ClientID %>').multiselect(
		{ sortable : <%=Sortable.ToString().ToLower() %> }
	);
});
</script>
	