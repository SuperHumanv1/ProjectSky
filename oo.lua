-- [[ SimpleSpy Official - Music Bypass UI ]] --
-- โดย ffsww_1007

local Player = game.Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

-- ลบ UI เก่า
if game.CoreGui:FindFirstChild("MusicBypassUI") then
    game.CoreGui.MusicBypassUI:Destroy()
end

-- --- [ CONFIG & ENCRYPTION ] ---
local PAD_LENGTH = 1000
-- ปิดการใช้ Mask (ใช้เป็น 0) เพื่อให้ ID ตรงกับที่เซิร์ฟเวอร์ต้องการ
local SECRET_MASK = 0 

local D = {
    [2]  = "\82\101\112\108\105\99\97\116\101\100\83\116\111\114\97\103\101", -- ReplicatedStorage
    [14] = "\80\108\97\121\101\114\84\111\111\108\69\118\101\110\116",       -- PlayerToolEvent
    [15] = "\84\111\111\108\77\117\115\105\99\84\101\120\116"                -- ToolMusicText
}

local function decStrToHex(s)
    local chars = "0123456789ABCDEF"
    local hexResult = ""
    while s ~= "0" and s ~= "" do
        local remainder = 0
        local newS = ""
        for i = 1, #s do
            local d = tonumber(string.sub(s, i, i))
            remainder = remainder * 10 + d
            if newS ~= "" or remainder >= 16 then
                newS = newS .. tostring(math.floor(remainder / 16))
                remainder = remainder % 16
            end
        end
        hexResult = string.sub(chars, remainder + 1, remainder + 1) .. hexResult
        s = newS ~= "" and newS or "0"
    end
    return hexResult ~= "" and hexResult or "0"
end

local function encodeID(numStr)
    local cleaned = tostring(numStr):match("%d+")
    if not cleaned then return "" end
    
    -- ใช้ ID ตรงๆ (บวก 0) เพื่อให้เปิดติดชัวร์
    local maskedVal = tostring(tonumber(cleaned) + SECRET_MASK)
    local hex = decStrToHex(maskedVal)
    
    -- ส่งคืนค่า Hex 1000 หลัก (เติม 0 ข้างหน้า)
    return "0x" .. string.rep("0", PAD_LENGTH - #hex) .. hex
end

-- --- [ UI SETUP ] ---
local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
ScreenGui.Name = "MusicBypassUI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 240, 0, 190)
MainFrame.Position = UDim2.new(0.5, -120, 0.5, -95)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 0, 0)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
Instance.new("UICorner", MainFrame)

local UIGradient = Instance.new("UIGradient", MainFrame)
UIGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 0, 0)), 
    ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 0, 0))
}

-- ระบบลาก
local dragging, dragStart, startPos
MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true; dragStart = input.Position; startPos = MainFrame.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input) dragging = false end)

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 40); Title.BackgroundTransparency = 1
Title.Text = "SKYSOUND REMOTE"; Title.TextColor3 = Color3.fromRGB(255, 0, 0)
Title.Font = Enum.Font.SpecialElite; Title.TextSize = 18

local IDInput = Instance.new("TextBox", MainFrame)
IDInput.Size = UDim2.new(0.85, 0, 0, 35); IDInput.Position = UDim2.new(0.075, 0, 0.3, 0)
IDInput.BackgroundColor3 = Color3.fromRGB(30, 0, 0); IDInput.TextColor3 = Color3.fromRGB(255, 255, 255)
IDInput.PlaceholderText = "Enter Audio ID..."; IDInput.Text = ""
IDInput.Font = Enum.Font.SpecialElite; IDInput.TextSize = 14
Instance.new("UICorner", IDInput)

local PlayBtn = Instance.new("TextButton", MainFrame)
PlayBtn.Size = UDim2.new(0.85, 0, 0, 40); PlayBtn.Position = UDim2.new(0.075, 0, 0.6, 0)
PlayBtn.BackgroundColor3 = Color3.fromRGB(100, 0, 0); PlayBtn.Text = "PLAY MUSIC"
PlayBtn.TextColor3 = Color3.fromRGB(255, 255, 255); PlayBtn.Font = Enum.Font.SpecialElite
PlayBtn.TextSize = 16
Instance.new("UICorner", PlayBtn)

-- --- [ LOGIC ] ---
PlayBtn.MouseButton1Click:Connect(function()
    local id = IDInput.Text
    if id ~= "" then
        local encoded = encodeID(id)
        
        -- ดึง Remote ตามลำดับ ReplicatedStorage -> RE -> PlayerToolEvent
        local rs = game:GetService(D[2])
        local re = rs:WaitForChild("RE", 5)
        
        if re then
            local event = re:WaitForChild(D[14], 5)
            if event then
                -- รูปแบบการส่งแบบ Unpack Args [4] = true
                local args = {
                    [1] = D[15],   -- "ToolMusicText"
                    [2] = encoded, -- ID แบบ Hex (1000 หลัก)
                    [4] = true
                }
                
                event:FireServer(unpack(args))
                
                PlayBtn.Text = "SENT!"
                task.wait(1)
                PlayBtn.Text = "PLAY MUSIC"
            end
        end
    end
end)