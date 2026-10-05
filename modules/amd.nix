{ ... }:

{
  # Both AMD GPUs use the kernel's amdgpu driver and Mesa.
  # Include 32-bit graphics libraries for future Steam/Proton use.
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
}
