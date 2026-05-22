import { Controller, Get, Post, Body, Patch, Param, Delete, UseGuards, ParseUUIDPipe, Query } from '@nestjs/common';
import { CategoriesService } from './categories.service';
import { CreateCategoryDto } from './dto/create-category.dto';
import { UpdateCategoryDto } from './dto/update-category.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { TenantGuard } from '../auth/guards/tenant.guard';
import { PermissionsGuard } from '../auth/guards/permissions.guard';
import { Permissions } from '../auth/decorators/permissions.decorator';
import { ActiveBarId } from '../auth/decorators/active-bar-id.decorator';

@Controller('categories')
@UseGuards(JwtAuthGuard, TenantGuard, PermissionsGuard)
export class CategoriesController {
  constructor(private readonly categoriesService: CategoriesService) {}

  @Post()
  @Permissions('productos.gestionar')
  create(@Body() createCategoryDto: CreateCategoryDto, @ActiveBarId() barId: string) {
    return this.categoriesService.create(createCategoryDto, barId);
  }

  @Get()
  findAll(
    @ActiveBarId() barId: string,
    @Query('admin') admin?: string,
  ) {
    const isAdmin = admin === 'true';
    return this.categoriesService.findAll(barId, isAdmin);
  }

  @Get(':id')
  findOne(@Param('id', ParseUUIDPipe) id: string, @ActiveBarId() barId: string) {
    return this.categoriesService.findOne(id, barId);
  }


  @Patch(':id')
  @Permissions('productos.gestionar')
  update(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() updateCategoryDto: UpdateCategoryDto,
    @ActiveBarId() barId: string,
  ) {
    return this.categoriesService.update(id, updateCategoryDto, barId);
  }

  @Delete(':id')
  @Permissions('productos.gestionar')
  remove(@Param('id', ParseUUIDPipe) id: string, @ActiveBarId() barId: string) {
    return this.categoriesService.remove(id, barId);
  }
}
