if vim.g.loaded_simpleterm then
  return
end

vim.g.loaded_simpleterm = 1

vim.api.nvim_create_user_command("SimpletermToggle", function()
  require("simpleterm").toggle()
end, {
  desc = "Toggle the simpleterm terminal",
})

require("simpleterm").setup()
