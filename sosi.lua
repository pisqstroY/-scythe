rconsolecreate()
local RunService = game:GetService("RunService")
local function onRenderStep(deltaTime)
rconsoleprint("хуйня твой ддос")
    print("Кадр обновился! Прошло времени: " .. deltaTime)
end
RunService.RenderStepped:Connect(onRenderStep)
