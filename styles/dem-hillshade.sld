<?xml version="1.0" encoding="UTF-8"?>
<!-- 第 04 集：DEM 山体阴影（ShadedRelief）。ReliefFactor 越大起伏越夸张；
     单波段 DEM 不需要 ChannelSelection，GeoServer 自动按灰度处理。
     想"伪彩色 + 阴影"叠加效果，见教案里 SLD 透明叠加的做法。 -->
<StyledLayerDescriptor version="1.0.0"
  xsi:schemaLocation="http://www.opengis.net/sld StyledLayerDescriptor.xsd"
  xmlns="http://www.opengis.net/sld"
  xmlns:ogc="http://www.opengis.net/ogc"
  xmlns:xlink="http://www.w3.org/1999/xlink"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <NamedLayer>
    <Name>ep04:dem_beijing</Name>
    <UserStyle>
      <Title>DEM 山体阴影</Title>
      <FeatureTypeStyle>
        <Rule>
          <RasterSymbolizer>
            <Opacity>1.0</Opacity>
            <ShadedRelief>
              <BrightnessOnly>false</BrightnessOnly>
              <ReliefFactor>55</ReliefFactor>
            </ShadedRelief>
          </RasterSymbolizer>
        </Rule>
      </FeatureTypeStyle>
    </UserStyle>
  </NamedLayer>
</StyledLayerDescriptor>
