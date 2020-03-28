import-module ./XmlUtils.psm1
$ErrorActionPreference = "Stop"

describe "XmlUtils" {
    it "replaces xml" {
        #Set up variables
        [xml] $xml = "<a><b><b1>1</b1><c/><b2>2</b2></b><b><d/></b></a>"
        $xml.PreserveWhiteSpace = $true
        [xml] $newXml = "<c><e>stuff and things</e></c>"

        #Test the find/replace function
        ReplaceXmlNode $xml "//c" $newXml

        #assert the results
        $xml.OuterXml | Should Be "<a><b><b1>1</b1><c><e>stuff and things</e></c><b2>2</b2></b><b><d /></b></a>"
    }

    it "replaces xml node with specific attribute" {
        #Set up variables
        [xml] $xml = '<a><b name="1">b1</b><b name="2">b2</b></a>'
        $xml.PreserveWhiteSpace = $true
        [xml] $newXml = '<c name="1">c1</c>'

        #Test the find/replace function
        ReplaceXmlNode $xml "//b[@name=1]" $newXml

        #assert the results
        $xml.OuterXml | Should Be '<a><c name="1">c1</c><b name="2">b2</b></a>'
    }

    it "replaces xml node with underscore name" {
        #Set up variables
        [xml] $xml = '<a><_b name="1">b1</_b><b name="2">b2</b></a>'
        $xml.PreserveWhiteSpace = $true
        [xml] $newXml = '<c name="1">c1</c>'

        #Test the find/replace function
        ReplaceXmlNode $xml "//_b" $newXml

        #assert the results
        $xml.OuterXml | Should Be '<a><c name="1">c1</c><b name="2">b2</b></a>'
    }
}