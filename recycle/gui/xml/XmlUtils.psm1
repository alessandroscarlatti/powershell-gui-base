$ErrorActionPreference = "Stop"

Function ReplaceXmlNode([xml] $xml, $xpath, [xml] $newXml) {
    $newNode = $xml.ImportNode($newXml.DocumentElement, $true)
    $targetNode = $xml.SelectSingleNode($xpath)
    $targetNode.ParentNode.InsertAfter($newNode, $targetNode) | out-null
    $targetNode.ParentNode.RemoveChild($targetNode) | out-null
}