<?xml version="1.0" encoding="UTF-8"?>
<!-- 第 04 集：DEM 伪彩色（按高程分段渐变）。ColorMap type="ramp" 在相邻色标间线性插值。 -->
<StyledLayerDescriptor version="1.0.0"
  xsi:schemaLocation="http://www.opengis.net/sld StyledLayerDescriptor.xsd"
  xmlns="http://www.opengis.net/sld"
  xmlns:ogc="http://www.opengis.net/ogc"
  xmlns:xlink="http://www.w3.org/1999/xlink"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <NamedLayer>
    <Name>ep04:dem_beijing</Name>
    <UserStyle>
      <Title>DEM 伪彩色（高程分层设色）</Title>
      <FeatureTypeStyle>
        <Rule>
          <RasterSymbolizer>
            <Opacity>1.0</Opacity>
            <ChannelSelection>
              <GrayChannel>
                <SourceChannelName>1</SourceChannelName>
              </GrayChannel>
            </ChannelSelection>
            <ColorMap type="ramp" extended="true">
              <ColorMapEntry color="#000000" quantity="-9999" label="nodata" opacity="0"/>
              <ColorMapEntry color="#2166ac" quantity="-50" label="-50 m（洼地）"/>
              <ColorMapEntry color="#67a9cf" quantity="50" label="50 m"/>
              <ColorMapEntry color="#d1e5f0" quantity="200" label="200 m"/>
              <ColorMapEntry color="#a1d76a" quantity="400" label="400 m"/>
              <ColorMapEntry color="#fee08b" quantity="800" label="800 m"/>
              <ColorMapEntry color="#f46d43" quantity="1200" label="1200 m"/>
              <ColorMapEntry color="#a50026" quantity="1800" label="1800 m"/>
              <ColorMapEntry color="#67001f" quantity="2200" label="2200 m（山峰）"/>
            </ColorMap>
          </RasterSymbolizer>
        </Rule>
      </FeatureTypeStyle>
    </UserStyle>
  </NamedLayer>
</StyledLayerDescriptor>
