import { Controller, Get, Param } from '@nestjs/common';
import { MenuService } from './menu.service';

@Controller('menu')
export class MenuController {
  constructor(private readonly menuService: MenuService) {}

  @Get(':slug')
  getBarProfile(@Param('slug') slug: string) {
    return this.menuService.getBarProfile(slug);
  }

  @Get(':slug/productos')
  getBarCatalog(@Param('slug') slug: string) {
    return this.menuService.getBarCatalog(slug);
  }
}
