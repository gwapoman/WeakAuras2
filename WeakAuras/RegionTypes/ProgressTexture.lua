local L = WeakAuras.L;

-- Credit to CommanderSirow for taking the time to properly craft the ApplyTransform function
-- to the enhance the abilities of Progress Textures.
-- Also Credit to Semlar for explaining how circular progress can be shown

-- NOTES:
--  Most SetValue() changes are quite equal (among compress/non-compress)
--  (There is no GUI button for mirror_v, but mirror_h)
--  New/Used variables
--   region.user_x (0) - User defined center x-shift [-1, 1]
--   region.user_y (0) - User defined center y-shift [-1, 1]
--   region.mirror_v (false) - Mirroring along x-axis [bool]
--   region.mirror_h (false) - Mirroring along y-axis [bool]
--   region.cos_rotation (1) - cos(ANGLE), precalculated cos-function for given ANGLE [-1, 1]
--   region.sin_rotation (0) - sin(ANGLE), precalculated cos-function for given ANGLE [-1, 1]
--   region.scale (1.0) - user defined scaling [1, INF]
--   region.full_rotation (false) - Allow full rotation [bool]


local function ApplyTransform(x, y, region)
  -- 1) Translate texture-coords to user-defined center
  x = x - 0.5
  y = y - 0.5

  -- 2) Shrink texture by 1/sqrt(2)
  x = x * 1.4142
  y = y * 1.4142

  -- Not yet supported for circular progress
  -- 3) Scale texture by user-defined amount
  x = x / region.scale_x
  y = y / region.scale_y

  -- 4) Apply mirroring if defined
  if region.mirror_h then
    x = -x
  end
  if region.mirror_v then
    y = -y
  end

  -- 5) Rotate texture by user-defined value
  x, y = region.cos_rotation * x - region.sin_rotation * y, region.sin_rotation * x + region.cos_rotation * y

  -- 6) Translate texture-coords back to (0,0)
  x = x + 0.5
  y = y + 0.5

  x = x + region.user_x
  y = y + region.user_y

  return x, y
end

local default = {
  foregroundTexture = "Textures\\SpellActivationOverlays\\Eclipse_Sun",
  backgroundTexture = "Textures\\SpellActivationOverlays\\Eclipse_Sun",
  desaturateBackground = false,
  desaturateForeground = false,
  sameTexture = true,
  compress = false,
  blendMode = "BLEND",
  backgroundOffset = 2,
  width = 200,
  height = 200,
  orientation = "VERTICAL",
  inverse = false,
  alpha = 1.0,
  foregroundColor = {1, 1, 1, 1},
  backgroundColor = {0.5, 0.5, 0.5, 0.5},
  startAngle = 0,
  endAngle = 360,
  user_x = 0,
  user_y = 0,
  crop_x = 0.41,
  crop_y = 0.41,
  crop = 0.41,
  rotation = 0,
  selfPoint = "CENTER",
  anchorPoint = "CENTER",
  anchorFrameType = "SCREEN",
  xOffset = 0,
  yOffset = 0,
  font = "Friz Quadrata TT",
  fontSize = 12,
  stickyDuration = false,
  mirror = false,
  frameStrata = 1,
  version = 2
};

WeakAuras.regionPrototype.AddAdjustedDurationToDefault(default);

local screenWidth, screenHeight = math.ceil(GetScreenWidth() / 20) * 20, math.ceil(GetScreenHeight() / 20) * 20;

local properties = {
  desaturateForeground = {
    display = L["Desaturate Foreground"],
    setter = "SetForegroundDesaturated",
    type = "bool",
  },
  desaturateBackground = {
    display = L["Desaturate Background"],
    setter = "SetBackgroundDesaturated",
    type = "bool",
  },
  foregroundColor = {
    display = L["Foreground Color"],
    setter = "Color",
    type = "color"
  },
  backgroundColor = {
    display = L["Background Color"],
    setter = "SetBackgroundColor",
    type = "color"
  },
  width = {
    display = L["Width"],
    setter = "SetRegionWidth",
    type = "number",
    min = 1,
    softMax = screenWidth,
    bigStep = 1,
  },
  height = {
    display = L["Height"],
    setter = "SetRegionHeight",
    type = "number",
    min = 1,
    softMax = screenHeight,
    bigStep = 1
  },
  orientation = {
    display = L["Orientation"],
    setter = "SetOrientation",
    type = "list",
    values = WeakAuras.orientation_with_circle_types
  },
  inverse = {
    display = L["Inverse"],
    setter = "SetInverse",
    type = "bool"
  }
}

WeakAuras.regionPrototype.AddProperties(properties);

local spinnerFunctions = {};

function spinnerFunctions.SetTexture(self, texture)
  for i = 1, 3 do
    self.textures[i]:SetTexture(texture);
  end
end

function spinnerFunctions.SetDesaturated(self, desaturate)
  for i = 1, 3 do
    self.textures[i]:SetDesaturated(desaturate);
  end
end

function spinnerFunctions.SetBlendMode(self, blendMode)
  for i = 1, 3 do
    self.textures[i]:SetBlendMode(blendMode);
  end
end

function spinnerFunctions.Show(self)
  for i = 1, 3 do
    self.textures[i]:Show();
  end
end

function spinnerFunctions.Hide(self)
  for i = 1, 3 do
    self.textures[i]:Hide();
  end
end

function spinnerFunctions.Color(self, r, g, b, a)
  for i = 1, 3 do
    self.textures[i]:SetVertexColor(r, g, b, a);
  end
end

function spinnerFunctions.SetProgress(self, region, angle1, angle2)
  local scalex = region.scale_x or 1;
  local scaley = region.scale_y or 1;
  local rotation = region.rotation or 0;
  local mirror_h = region.mirror_h or false;
  local mirror_v = region.mirror_v or false;

  if (angle2 - angle1 >= 360) then
    -- SHOW everything
    self.coords[1]:SetFull();
    self.coords[1]:Transform(scalex, scaley, rotation, mirror_h, mirror_v);
    self.coords[1]:Show();

    self.coords[2]:Hide();
    self.coords[3]:Hide();
    return;
  end
  if (angle1 == angle2) then
    self.coords[1]:Hide();
    self.coords[2]:Hide();
    self.coords[3]:Hide();
    return;
  end

  local index1 = floor((angle1 + 45) / 90);
  local index2 = floor((angle2 + 45) / 90);

  if (index1 + 1 >= index2) then
    self.coords[1]:SetAngle(angle1, angle2);
    self.coords[1]:Transform(scalex, scaley, rotation, mirror_h, mirror_v);
    self.coords[1]:Show();
    self.coords[2]:Hide();
    self.coords[3]:Hide();
  elseif(index1 + 3 >= index2) then
    local firstEndAngle = (index1 + 1) * 90 + 45;
    self.coords[1]:SetAngle(angle1, firstEndAngle);
    self.coords[1]:Transform(scalex, scaley, rotation, mirror_h, mirror_v);
    self.coords[1]:Show();

    self.coords[2]:SetAngle(firstEndAngle, angle2);
    self.coords[2]:Transform(scalex, scaley, rotation, mirror_h, mirror_v);
    self.coords[2]:Show();

    self.coords[3]:Hide();
  else
    local firstEndAngle = (index1 + 1) * 90 + 45;
    local secondEndAngle = firstEndAngle + 180;

    self.coords[1]:SetAngle(angle1, firstEndAngle);
    self.coords[1]:Transform(scalex, scaley, rotation, mirror_h, mirror_v);
    self.coords[1]:Show();

    self.coords[2]:SetAngle(firstEndAngle, secondEndAngle);
    self.coords[2]:Transform(scalex, scaley, rotation, mirror_h, mirror_v);
    self.coords[2]:Show();

    self.coords[3]:SetAngle(secondEndAngle, angle2);
    self.coords[3]:Transform(scalex, scaley, rotation, mirror_h, mirror_v);
    self.coords[3]:Show();
  end
end

function spinnerFunctions.SetBackgroundOffset(self, region, offset)
  for i = 1, 3 do
    self.textures[i]:SetPoint('TOPRIGHT', region, offset, offset)
    self.textures[i]:SetPoint('BOTTOMRIGHT', region, offset, -offset)
    self.textures[i]:SetPoint('BOTTOMLEFT', region, -offset, -offset)
    self.textures[i]:SetPoint('TOPLEFT', region, -offset, offset)
  end
end

function spinnerFunctions:SetHeight(height)
  for i = 1, 3 do
    self.textures[i]:SetHeight(height);
  end
end

function spinnerFunctions:SetWidth(width)
  for i = 1, 3 do
    self.textures[i]:SetWidth(width);
  end
end

local defaultTexCoord = {
  ULx = 0,
  ULy = 0,
  LLx = 0,
  LLy = 1,
  URx = 1,
  URy = 0,
  LRx = 1,
  LRy = 1,
};

local function createTexCoord(texture)
  local coord = {
    ULx = 0,
    ULy = 0,
    LLx = 0,
    LLy = 1,
    URx = 1,
    URy = 0,
    LRx = 1,
    LRy = 1,

    ULvx = 0,
    ULvy = 0,
    LLvx = 0,
    LLvy = 0,
    URvx = 0,
    URvy = 0,
    LRvx = 0,
    LRvy = 0,

    texture = texture;
  };

  function coord:MoveCorner(corner, x, y)
    local width, height = self.texture:GetSize();
    local rx = defaultTexCoord[corner .. "x"] - x;
    local ry = defaultTexCoord[corner .. "y"] - y;
    coord[corner .. "vx"] = -rx * width;
    coord[corner .. "vy"] = ry * height;

    coord[corner .. "x"] = x;
    coord[corner .. "y"] = y;
  end

  function coord:Hide()
    coord.texture:Hide();
  end

  function coord:Show()
    coord:Apply();
    coord.texture:Show();
  end

  function coord:SetFull()
    coord.ULx = 0;
    coord.ULy = 0;
    coord.LLx = 0;
    coord.LLy = 1;
    coord.URx = 1;
    coord.URy = 0;
    coord.LRx = 1;
    coord.LRy = 1;

    coord.ULvx = 0;
    coord.ULvy = 0;
    coord.LLvx = 0;
    coord.LLvy = 0;
    coord.URvx = 0;
    coord.URvy = 0;
    coord.LRvx = 0;
    coord.LRvy = 0;
  end

  function coord:Apply()
    coord.texture:SetVertexOffset(UPPER_RIGHT_VERTEX, coord.URvx, coord.URvy);
    coord.texture:SetVertexOffset(UPPER_LEFT_VERTEX, coord.ULvx, coord.ULvy);
    coord.texture:SetVertexOffset(LOWER_RIGHT_VERTEX, coord.LRvx, coord.LRvy);
    coord.texture:SetVertexOffset(LOWER_LEFT_VERTEX, coord.LLvx, coord.LLvy);

    coord.texture:SetTexCoord(coord.ULx, coord.ULy, coord.LLx, coord.LLy, coord.URx, coord.URy, coord.LRx, coord.LRy);
  end

  local exactAngles = {
    {0.5, 0},  -- 0°
    {1, 0},    -- 45°
    {1, 0.5},  -- 90°
    {1, 1},    -- 135°
    {0.5, 1},  -- 180°
    {0, 1},    -- 225°
    {0, 0.5},  -- 270°
    {0, 0}     -- 315°
  }

  local function angleToCoord(angle)
    angle = angle % 360;

    if (angle % 45 == 0) then
      local index = floor (angle / 45) + 1;
      return exactAngles[index][1], exactAngles[index][2];
    end

    if (angle < 45) then
      return 0.5 + tan(angle) / 2, 0;
    elseif (angle < 135) then
      return 1, 0.5 + tan(angle - 90) / 2 ;
    elseif (angle < 225) then
      return 0.5 - tan(angle) / 2, 1;
    elseif (angle < 315) then
      return 0, 0.5 - tan(angle - 90) / 2;
    elseif (angle < 360) then
      return 0.5 + tan(angle) / 2, 0;
    end
  end

  local pointOrder = { "LL", "UL", "UR", "LR", "LL", "UL", "UR", "LR", "LL", "UL", "UR", "LR" }

  function coord:SetAngle(angle1, angle2)
    local index = floor((angle1 + 45) / 90);

    local middleCorner = pointOrder[index + 1];
    local startCorner = pointOrder[index + 2];
    local endCorner1 = pointOrder[index + 3];
    local endCorner2 = pointOrder[index + 4];

    -- LL => 32, 32
    -- UL => 32, -32
    self:MoveCorner(middleCorner, 0.5, 0.5)
    self:MoveCorner(startCorner, angleToCoord(angle1));

    local edge1 = floor((angle1 - 45) / 90);
    local edge2 = floor((angle2 -45) / 90);

    if (edge1 == edge2) then
      self:MoveCorner(endCorner1, angleToCoord(angle2));
    else
      self:MoveCorner(endCorner1, defaultTexCoord[endCorner1 .. "x"], defaultTexCoord[endCorner1 .. "y"]);
    end

    self:MoveCorner(endCorner2, angleToCoord(angle2));
  end

  local function TransformPoint(x, y, scalex, scaley, rotation, mirror_h, mirror_v)
    -- 1) Translate texture-coords to user-defined center
    x = x - 0.5
    y = y - 0.5

    -- 2) Shrink texture by 1/sqrt(2)
    x = x * 1.4142
    y = y * 1.4142

    -- Not yet supported for circular progress
    -- 3) Scale texture by user-defined amount
    x = x / scalex
    y = y / scaley

    -- 4) Apply mirroring if defined
    if mirror_h then
      x = -x
    end
    if mirror_v then
      y = -y
    end

    local cos_rotation = cos(rotation);
    local sin_rotation = sin(rotation);

    -- 5) Rotate texture by user-defined value
    x, y = cos_rotation * x - sin_rotation * y, sin_rotation * x + cos_rotation * y

    -- 6) Translate texture-coords back to (0,0)
    x = x + 0.5
    y = y + 0.5

    return x, y
  end

  function coord:Transform(scalex, scaley, rotation, mirror_h, mirror_v)
    coord.ULx, coord.ULy = TransformPoint(coord.ULx, coord.ULy, scalex, scaley, rotation, mirror_h, mirror_v);
    coord.LLx, coord.LLy = TransformPoint(coord.LLx, coord.LLy, scalex, scaley, rotation, mirror_h, mirror_v);
    coord.URx, coord.URy = TransformPoint(coord.URx, coord.URy, scalex, scaley, rotation, mirror_h, mirror_v);
    coord.LRx, coord.LRy = TransformPoint(coord.LRx, coord.LRy, scalex, scaley, rotation, mirror_h, mirror_v);
  end

  return coord;
end


local function createSpinner(parent, layer)
  local spinner = {};
  spinner.textures = {};
  spinner.coords = {};

  for i = 1, 3 do
    local texture = parent:CreateTexture(nil, layer);
    texture:SetAllPoints(parent);
    spinner.textures[i] = texture;

    spinner.coords[i] = createTexCoord(texture);
  end

  for k, v in pairs(spinnerFunctions) do
    spinner[k] = v;
  end

  return spinner;
end

-- Make available for the thumbnail display
WeakAuras.createSpinner = createSpinner;


local SetValueFunctions = {
  ["HORIZONTAL"] = {
    [true] = function(self, progress)
      self.progress = progress;

      local ULx, ULy = ApplyTransform(0, 0, self)
      local LLx, LLy = ApplyTransform(0, 1, self)
      local URx, URy = ApplyTransform(1, 0, self)
      local LRx, LRy = ApplyTransform(1, 1, self)

      self.foreground:SetTexCoord(ULx, ULy, LLx, LLy, URx, URy, LRx, LRy);
      self.foreground:SetWidth(self:GetWidth() * progress);
      self.background:SetTexCoord(ULx, ULy, LLx, LLy, URx, URy, LRx, LRy);
    end,
    [false] = function(self, progress)
      self.progress = progress;

      local ULx , ULy  = ApplyTransform(0, 0, self)
      local LLx , LLy  = ApplyTransform(0, 1, self)
      local URx , URy  = ApplyTransform(progress, 0, self)
      local URx_, URy_ = ApplyTransform(1, 0, self)
      local LRx , LRy  = ApplyTransform(progress, 1, self)
      local LRx_, LRy_ = ApplyTransform(1, 1, self)

      self.foreground:SetTexCoord(ULx, ULy, LLx, LLy, URx , URy , LRx , LRy );
      self.foreground:SetWidth(self:GetWidth() * progress);
      self.background:SetTexCoord(ULx, ULy, LLx, LLy, URx_, URy_, LRx_, LRy_);
    end
  },
  ["HORIZONTAL_INVERSE"] = {
    [true] = function(self, progress)
      self.progress = progress;

      local ULx, ULy = ApplyTransform(0, 0, self)
      local LLx, LLy = ApplyTransform(0, 1, self)
      local URx, URy = ApplyTransform(1, 0, self)
      local LRx, LRy = ApplyTransform(1, 1, self)

      self.foreground:SetTexCoord(ULx, ULy, LLx, LLy, URx, URy, LRx, LRy);
      self.foreground:SetWidth(self:GetWidth() * progress);
      self.background:SetTexCoord(ULx, ULy, LLx, LLy, URx, URy, LRx, LRy);
    end,
    [false] = function(self, progress)
      self.progress = progress;

      local ULx , ULy  = ApplyTransform(1 - progress, 0, self)
      local ULx_, ULy_ = ApplyTransform(0, 0, self)
      local LLx , LLy  = ApplyTransform(1 - progress, 1, self)
      local LLx_, LLy_ = ApplyTransform(0, 1, self)
      local URx , URy  = ApplyTransform(1, 0, self)
      local LRx , LRy  = ApplyTransform(1, 1, self)

      self.foreground:SetTexCoord(ULx , ULy , LLx , LLy , URx, URy, LRx, LRy);
      self.foreground:SetWidth(self:GetWidth() * progress);
      self.background:SetTexCoord(ULx_, ULy_, LLx_, LLy_, URx, URy, LRx, LRy);
      end
  },
  ["VERTICAL"] = {
    [true] = function(self, progress)
      self.progress = progress;

      local ULx, ULy = ApplyTransform(0, 0, self)
      local LLx, LLy = ApplyTransform(0, 1, self)
      local URx, URy = ApplyTransform(1, 0, self)
      local LRx, LRy = ApplyTransform(1, 1, self)

      self.foreground:SetTexCoord(ULx, ULy, LLx, LLy, URx, URy, LRx, LRy);
      self.foreground:SetHeight(self:GetHeight() * progress);
      self.background:SetTexCoord(ULx, ULy, LLx, LLy, URx, URy, LRx, LRy);
    end,
    [false] = function(self, progress)
      self.progress = progress;

      local ULx , ULy  = ApplyTransform(0, 1 - progress, self)
      local ULx_, ULy_ = ApplyTransform(0, 0, self)
      local LLx , LLy  = ApplyTransform(0, 1, self)
      local URx , URy  = ApplyTransform(1, 1 - progress, self)
      local URx_, URy_ = ApplyTransform(1, 0, self)
      local LRx , LRy  = ApplyTransform(1, 1, self)

      self.foreground:SetTexCoord(ULx, ULy, LLx, LLy, URx, URy, LRx, LRy);
      self.foreground:SetHeight(self:GetHeight() * progress);
      self.background:SetTexCoord(ULx_, ULy_, LLx, LLy, URx_, URy_, LRx, LRy);
    end
  },
  ["VERTICAL_INVERSE"] = {
    [true] = function(self, progress)
      self.progress = progress;

      local ULx, ULy = ApplyTransform(0, 0, self)
      local LLx, LLy = ApplyTransform(0, 1, self)
      local URx, URy = ApplyTransform(1, 0, self)
      local LRx, LRy = ApplyTransform(1, 1, self)

      self.foreground:SetTexCoord(ULx, ULy, LLx, LLy, URx, URy, LRx, LRy);
      self.foreground:SetHeight(self:GetHeight() * progress);
      self.background:SetTexCoord(ULx, ULy, LLx, LLy, URx, URy, LRx, LRy);
    end,
    [false] = function(self, progress)
      self.progress = progress;
      local ULx , ULy  = ApplyTransform(0, 0, self)
      local LLx , LLy  = ApplyTransform(0, progress, self)
      local LLx_, LLy_ = ApplyTransform(0, 1, self)
      local URx , URy  = ApplyTransform(1, 0, self)
      local LRx , LRy  = ApplyTransform(1, progress, self)
      local LRx_, LRy_ = ApplyTransform(1, 1, self)
      self.foreground:SetTexCoord(ULx, ULy, LLx, LLy, URx, URy, LRx, LRy);
      self.foreground:SetHeight(self:GetHeight() * progress);
      self.background:SetTexCoord(ULx, ULy, LLx_, LLy_, URx, URy, LRx_, LRy_);
    end
  },
  ["CLOCKWISE"] = function(self, progress)
    local startAngle = self.startAngle;
    local endAngle = self.endAngle;
    progress = progress or 0;
    self.progress = progress;

    if (progress < 0) then
      progress = 0;
    end

    if (progress > 1) then
      progress = 1;
    end

    local pAngle = (endAngle - startAngle) * progress + startAngle;
    self.foregroundSpinner:SetProgress(self, startAngle, pAngle);
  end,
  ["ANTICLOCKWISE"] = function(self, progress)
    local startAngle = self.startAngle;
    local endAngle = self.endAngle;
    progress = progress or 0;
    self.progress = progress;

    if (progress < 0) then
      progress = 0;
    end

    if (progress > 1) then
      progress = 1;
    end
    progress = 1 - progress;

    local pAngle = (endAngle - startAngle) * progress + startAngle;
    self.foregroundSpinner:SetProgress(self, pAngle, endAngle);
  end
}

local orientationToAnchorPoint = {
  ["HORIZONTAL"] = "LEFT",
  ["HORIZONTAL_INVERSE"] = "RIGHT",
  ["VERTICAL"] = "BOTTOM",
  ["VERTICAL_INVERSE"] = "TOP"
}

local function showCircularProgress(region)
  region.foreground:Hide();
  region.background:Hide();
  region.foregroundSpinner:Show();
  region.backgroundSpinner:Show();
end

local function hideCircularProgress(region)
  region.foreground:Show();
  region.background:Show();
  region.foregroundSpinner:Hide();
  region.backgroundSpinner:Hide();
end

local function SetOrientation(region, orientation)
  region.orientation = orientation;
  if(region.orientation == "CLOCKWISE" or region.orientation == "ANTICLOCKWISE") then
    showCircularProgress(region);
    region.backgroundSpinner:SetProgress(region, region.startAngle, region.endAngle);
    region.SetValueOnTexture = SetValueFunctions[region.orientation];
  else
    hideCircularProgress(region);
    region.foreground:ClearAllPoints();
    region.foreground:SetWidth(region.width * region.scalex);
    region.foreground:SetHeight(region.height * region.scaley);
    local anchor = orientationToAnchorPoint[region.orientation];
    region.foreground:SetPoint(anchor, region, anchor);
    region.SetValueOnTexture = SetValueFunctions[region.orientation][region.compress];
  end
  region:SetValueOnTexture(region.progress);
end

local function create(parent)
  local font = "GameFontHighlight";

  local region = CreateFrame("FRAME", nil, parent);
  region:SetMovable(true);
  region:SetResizable(true);
  region:SetMinResize(1, 1);

  local background = region:CreateTexture(nil, "BACKGROUND");
  region.background = background;

  -- For horizontal/vertical progress
  local foreground = region:CreateTexture(nil, "ARTWORK");
  region.foreground = foreground;

  region.foregroundSpinner = createSpinner(region, "ARTWORK", parent:GetFrameLevel() + 2);
  region.backgroundSpinner = createSpinner(region, "BACKGROUND", parent:GetFrameLevel() + 1);

  region.values = {};
  region.duration = 0;
  region.expirationTime = math.huge;

  region.SetOrientation = SetOrientation;

  WeakAuras.regionPrototype.create(region);

  return region;
end

local function modify(parent, region, data)
  WeakAuras.regionPrototype.modify(parent, region, data);

  local background, foreground = region.background, region.foreground;
  local foregroundSpinner, backgroundSpinner = region.foregroundSpinner, region.backgroundSpinner;

  region:SetWidth(data.width);
  region:SetHeight(data.height);
  region.width = data.width;
  region.height = data.height;
  region.scalex = 1;
  region.scaley = 1;
  region.aspect =  data.width / data.height;
  foreground:SetWidth(data.width);
  foreground:SetHeight(data.height);

  region:ClearAllPoints();
  WeakAuras.AnchorFrame(data, region, parent)
  region:SetAlpha(data.alpha);

  background:SetTexture(data.sameTexture and data.foregroundTexture or data.backgroundTexture);
  background:SetDesaturated(data.desaturateBackground)
  background:SetVertexColor(data.backgroundColor[1], data.backgroundColor[2], data.backgroundColor[3], data.backgroundColor[4]);
  background:SetBlendMode(data.blendMode);

  backgroundSpinner:SetTexture(data.sameTexture and data.foregroundTexture or data.backgroundTexture);
  backgroundSpinner:SetDesaturated(data.desaturateBackground)
  backgroundSpinner:Color(data.backgroundColor[1], data.backgroundColor[2], data.backgroundColor[3], data.backgroundColor[4]);
  backgroundSpinner:SetBlendMode(data.blendMode);

  foreground:SetTexture(data.foregroundTexture);
  foreground:SetDesaturated(data.desaturateForeground)
  foreground:SetBlendMode(data.blendMode);

  foregroundSpinner:SetTexture(data.foregroundTexture);
  foregroundSpinner:SetDesaturated(data.desaturateForeground);
  foregroundSpinner:SetBlendMode(data.blendMode);

  background:ClearAllPoints();
  foreground:ClearAllPoints();
  background:SetPoint("BOTTOMLEFT", region, "BOTTOMLEFT", -1 * data.backgroundOffset, -1 * data.backgroundOffset);
  background:SetPoint("TOPRIGHT", region, "TOPRIGHT", data.backgroundOffset, data.backgroundOffset);
  backgroundSpinner:SetBackgroundOffset(region, data.backgroundOffset);

  region.mirror_h = data.mirror;
  region.scale_x = 1 + (data.crop_x or 0.41);
  region.scale_y = 1 + (data.crop_y or 0.41);
  region.scale = 1 + (data.crop or 0.41);
  region.rotation = data.rotation or 0;
  region.cos_rotation = cos(region.rotation);
  region.sin_rotation = sin(region.rotation);
  region.user_x = -1 * (data.user_x or 0);
  region.user_y = data.user_y or 0;

  region.startAngle = (data.startAngle or 0) % 360;
  region.endAngle = (data.endAngle or 360) % 360;

  if (region.endAngle <= region.startAngle) then
    region.endAngle = region.endAngle + 360;
  end

  region.compress = data.compress;

  region.inverseDirection = data.inverse;
  region.progress = 0.667;
  region:SetOrientation(data.orientation);

  function region:Scale(scalex, scaley)
    region.scalex = scalex;
    region.scaley = scaley;
    foreground:ClearAllPoints();
    if(scalex < 0) then
      region.mirror_h = not data.mirror;
      scalex = scalex * -1;
    else
      region.mirror_h = data.mirror;
    end
    if(region.mirror_h) then
      if(data.orientation == "HORIZONTAL_INVERSE") then
        foreground:SetPoint("RIGHT", region, "RIGHT");
      elseif(data.orientation == "HORIZONTAL") then
        foreground:SetPoint("LEFT", region, "LEFT");
      end
    else
      if(data.orientation == "HORIZONTAL") then
        foreground:SetPoint("LEFT", region, "LEFT");
      elseif(data.orientation == "HORIZONTAL_INVERSE") then
        foreground:SetPoint("RIGHT", region, "RIGHT");
      end
    end
    if(scaley < 0) then
      region.mirror_v = true;
      scaley = scaley * -1;
      if(data.orientation == "VERTICAL_INVERSE") then
        foreground:SetPoint("TOP", region, "TOP");
      elseif(data.orientation == "VERTICAL") then
        foreground:SetPoint("BOTTOM", region, "BOTTOM");
      end
    else
      region.mirror_v = nil;
      if(data.orientation == "VERTICAL") then
        foreground:SetPoint("BOTTOM", region, "BOTTOM");
      elseif(data.orientation == "VERTICAL_INVERSE") then
        foreground:SetPoint("TOP", region, "TOP");
      end
    end

    region:SetWidth(region.width * scalex);
    region:SetHeight(region.height * scaley);

    if(data.orientation == "HORIZONTAL_INVERSE" or data.orientation == "HORIZONTAL") then
      foreground:SetWidth(region.width * scalex * (region.progress or 1));
      foreground:SetHeight(region.height * scaley);
    else
      foreground:SetWidth(region.width * scalex);
      foreground:SetHeight(region.height * scaley * (region.progress or 1));
    end
    background:SetPoint("BOTTOMLEFT", region, "BOTTOMLEFT", -1 * scalex * data.backgroundOffset, -1 * scaley * data.backgroundOffset);
    background:SetPoint("TOPRIGHT", region, "TOPRIGHT", scalex * data.backgroundOffset, scaley * data.backgroundOffset);
  end

  function region:Rotate(angle)
    region.rotation = angle or 0;
    region.cos_rotation = cos(region.rotation);
    region.sin_rotation = sin(region.rotation);
    region:SetValueOnTexture(region.progress);
  end

  function region:GetRotation()
    return region.rotation;
  end

  function region:Color(r, g, b, a)
    region.color_r = r;
    region.color_g = g;
    region.color_b = b;
    region.color_a = a;
    foreground:SetVertexColor(r, g, b, a);
    foregroundSpinner:Color(r, g, b, a);
  end

  function region:GetColor()
    return region.color_r or data.foregroundColor[1], region.color_g or data.foregroundColor[2],
      region.color_b or data.foregroundColor[3], region.color_a or data.foregroundColor[4];
  end

  region:Color(data.foregroundColor[1], data.foregroundColor[2], data.foregroundColor[3], data.foregroundColor[4]);

  function region:SetTime(duration, expirationTime, inverse)
    if (duration == 0) then
      region:SetValueOnTexture(1);
      return;
    end

    local remaining = expirationTime - GetTime();
    local progress = remaining / duration;

    if((region.inverseDirection and not inverse) or (inverse and not region.inverseDirection)) then
      progress = 1 - progress;
    end
    progress = progress > 0.0001 and progress or 0.0001;
    region:SetValueOnTexture(progress);
  end

  function region:SetValue(value, total)
    local progress = 1
    if(total > 0) then
      progress = value / total;
    end
    if(region.inverseDirection) then
      progress = 1 - progress;
    end
    progress = progress > 0.0001 and progress or 0.0001;
    region:SetValueOnTexture(progress);
  end

  function region:TimerTick()
    local adjustMin = region.adjustedMin or 0;
    self:SetTime( (region.adjustedMax or region.duration) - adjustMin, region.expirationTime - adjustMin, region.inverse);
  end

  function region:SetForegroundDesaturated(b)
    region.foreground:SetDesaturated(b);
    region.foregroundSpinner:SetDesaturated(b);
  end

  function region:SetBackgroundDesaturated(b)
    region.background:SetDesaturated(b);
    region.backgroundSpinner:SetDesaturated(b);
  end

  function region:SetBackgroundColor(r, g, b, a)
    region.background:SetVertexColor(r, g, b, a);
    region.backgroundSpinner:Color(r, g, b, a);
  end

  function region:SetRegionWidth(width)
    region.width = width;
    region:Scale(region.scalex, region.scaley);
  end

  function region:SetRegionHeight(height)
    region.height = height;
    region:Scale(region.scalex, region.scaley);
  end

  function region:SetInverse(inverse)
    region.inverseDirection = inverse;
    local progress = 1 - region.progress;
    progress = progress > 0.0001 and progress or 0.0001;
    region:SetValueOnTexture(progress);
  end
end

WeakAuras.RegisterRegionType("progresstexture", create, modify, default, properties);
