// src/app/products/[id]/page.jsx
"use client";

import React, { useState, useEffect } from "react";
import { useParams, useRouter } from "next/navigation";
import { useCart } from "@/contexts/CartContext";
import { productsAPI } from "@/services/api";
import BackButton from "@/components/BackButton";
import { getImageUrl } from "@/utils/imageUrl";

export default function ProductDetailPage() {
  const params = useParams();
  const { id } = params;
  const router = useRouter();
  const { addToCart } = useCart();

  const [product, setProduct] = useState(null);
  const [loading, setLoading] = useState(true);
  const [selectedVariant, setSelectedVariant] = useState(null);
  const [addedToCart, setAddedToCart] = useState(false);
  const [userRole, setUserRole] = useState(null);
  const [quantity, setQuantity] = useState(1);

  // Check if user is staff
  useEffect(() => {
    const userData = localStorage.getItem("user");
    if (userData) {
      const user = JSON.parse(userData);
      setUserRole(user.role);
      // Allow staff to view product details, just hide buy buttons
    }
  }, [router]);

  useEffect(() => {
    if (id) {
      const fetchProduct = async () => {
        try {
          setLoading(true);
          const data = await productsAPI.getProductById(id);
          setProduct(data);
          // Set default variant (is_default = 1) or first variant
          setSelectedVariant(
            data.variants?.find((v) => v.is_default === 1) || data.variants?.[0]
          );
          setLoading(false);
        } catch (error) {
          console.error("Error fetching product:", error);
          setLoading(false);
        }
      };
      fetchProduct();
    }
  }, [id]);

  const handleVariantChange = (variantId) => {
    setSelectedVariant(
      product.variants.find((v) => v.variant_id === variantId)
    );
    setAddedToCart(false);
    setQuantity(1); // Reset quantity when variant changes
  };

  // Get unique variant attributes
  const getUniqueAttributes = (attribute) => {
    return [
      ...new Set(product?.variants.map((v) => v[attribute]).filter(Boolean)),
    ];
  };

  // Find best matching variant when switching attributes
  const findMatchingVariant = (attributeType, attributeValue) => {
    // Try to find variant with same other attributes
    const candidates = product.variants.filter(
      (v) => v[attributeType] === attributeValue
    );

    if (candidates.length === 1) return candidates[0].variant_id;

    // Try to match other attributes from current selection
    const bestMatch = candidates.find((v) => {
      if (attributeType !== "color" && v.color === selectedVariant?.color)
        return true;
      if (attributeType !== "size" && v.size === selectedVariant?.size)
        return true;
      return false;
    });

    return bestMatch ? bestMatch.variant_id : candidates[0].variant_id;
  };

  const handleAddToCart = () => {
    // Check if user is logged in
    const token = localStorage.getItem("token");
    const customerId = localStorage.getItem("customer_id");

    if (!token || !customerId) {
      // Redirect to login page if not logged in
      router.push("/login");
      return;
    }

    if (selectedVariant) {
      addToCart(selectedVariant, quantity); // Use selected quantity
      setAddedToCart(true);
      setTimeout(() => {
        setAddedToCart(false);
      }, 3000);
    }
  };

  const handleBuyNow = async () => {
    // Check if user is logged in
    const token = localStorage.getItem("token");
    const customerId = localStorage.getItem("customer_id");

    if (!token || !customerId) {
      // Redirect to login page with return URL to checkout
      router.push("/login?redirect=/checkout");
      return;
    }

    if (selectedVariant) {
      // Redirect to checkout with product variant ID and quantity as URL params
      // This allows checkout page to show only this product, not the entire cart
      router.push(
        `/checkout?buyNow=true&variantId=${selectedVariant.variant_id}&quantity=${quantity}`
      );
    }
  };

  const incrementQuantity = () => {
    setQuantity((prev) => prev + 1);
  };

  const decrementQuantity = () => {
    setQuantity((prev) => (prev > 1 ? prev - 1 : 1));
  };

  const handleQuantityInput = (e) => {
    const value = parseInt(e.target.value);
    if (!isNaN(value) && value > 0) {
      setQuantity(value);
    }
  };

  if (loading) {
    return (
      <div className="container mx-auto px-4 py-12">
        <div className="text-center">
          <div className="text-6xl mb-4">⏳</div>
          <p className="text-text-primary text-xl">
            Loading product details...
          </p>
        </div>
      </div>
    );
  }

  if (!product) {
    return (
      <div className="container mx-auto px-4 py-12">
        <div className="text-center">
          <div className="text-6xl mb-4">❌</div>
          <h3 className="text-xl font-semibold text-text-primary mb-2">
            Product Not Found
          </h3>
          <p className="text-text-secondary">
            The product you're looking for doesn't exist.
          </p>
        </div>
      </div>
    );
  }

  const isInStock = selectedVariant && selectedVariant.stock_quantity > 0;
  const estimatedDelivery = isInStock
    ? "5-7 business days"
    : "8-10 business days (backorder)";

  // Get the image URL for the selected variant
  const imageUrl = getImageUrl(selectedVariant?.image_url);

  // Get all unique variant images for gallery (group by color)
  const variantImages = React.useMemo(() => {
    if (!product?.variants) return [];
    
    const imageMap = new Map();
    product.variants.forEach(variant => {
      const key = variant.color || 'default';
      if (variant.image_url && !imageMap.has(key)) {
        imageMap.set(key, {
          url: getImageUrl(variant.image_url),
          color: variant.color,
          variant_id: variant.variant_id
        });
      }
    });
    
    return Array.from(imageMap.values());
  }, [product?.variants]);

  // State for selected image (for gallery)
  const [currentImageIndex, setCurrentImageIndex] = React.useState(0);

  // Update current image when variant changes
  React.useEffect(() => {
    if (selectedVariant && variantImages.length > 0) {
      const matchingIndex = variantImages.findIndex(
        img => img.color === selectedVariant.color
      );
      if (matchingIndex !== -1) {
        setCurrentImageIndex(matchingIndex);
      }
    }
  }, [selectedVariant, variantImages]);

  const currentDisplayImage = variantImages.length > 0 
    ? variantImages[currentImageIndex].url 
    : imageUrl;

  return (
    <div className="container mx-auto px-4 py-8">
      {/* Back Button */}
      <div className="mb-6">
        <BackButton variant="outline" label="Back to Products" />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-12">
        {/* Image Gallery */}
        <div className="flex flex-col gap-4">
          {/* Main Image */}
          <div className="bg-card border border-card-border rounded-lg overflow-hidden relative group">
            {currentDisplayImage ? (
              <>
                <img
                  key={currentImageIndex} // Force re-render on image change
                  src={currentDisplayImage}
                  alt={`${product.name}${selectedVariant?.color ? ` - ${selectedVariant.color}` : ''}`}
                  className="w-full h-96 object-cover transition-opacity duration-300"
                  onError={(e) => {
                    e.target.onerror = null;
                    e.target.parentElement.innerHTML = `
                      <div class="h-96 flex items-center justify-center bg-gray-50 dark:bg-gray-800">
                        <div class="text-center">
                          <svg class="w-16 h-16 mx-auto mb-2 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"></path>
                          </svg>
                          <span class="text-text-secondary text-lg block font-semibold">${product.brand || "Product"}</span>
                          <span class="text-text-secondary text-sm">Image Not Available</span>
                        </div>
                      </div>
                    `;
                  }}
                />
                {/* Image navigation arrows - show if multiple images */}
                {variantImages.length > 1 && (
                  <>
                    <button
                      onClick={() => setCurrentImageIndex((prev) => 
                        prev === 0 ? variantImages.length - 1 : prev - 1
                      )}
                      className="absolute left-2 top-1/2 -translate-y-1/2 bg-black/50 hover:bg-black/70 text-white p-2 rounded-full opacity-0 group-hover:opacity-100 transition-opacity"
                      aria-label="Previous image"
                    >
                      <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
                      </svg>
                    </button>
                    <button
                      onClick={() => setCurrentImageIndex((prev) => 
                        prev === variantImages.length - 1 ? 0 : prev + 1
                      )}
                      className="absolute right-2 top-1/2 -translate-y-1/2 bg-black/50 hover:bg-black/70 text-white p-2 rounded-full opacity-0 group-hover:opacity-100 transition-opacity"
                      aria-label="Next image"
                    >
                      <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
                      </svg>
                    </button>
                  </>
                )}
                {/* Current variant badge */}
                {selectedVariant?.color && (
                  <div className="absolute top-4 left-4 bg-black/70 text-white px-3 py-1 rounded-full text-sm font-medium">
                    {selectedVariant.color}
                  </div>
                )}
              </>
            ) : (
              <div className="h-96 flex items-center justify-center bg-gray-50 dark:bg-gray-800">
                <div className="text-center">
                  <svg className="w-16 h-16 mx-auto mb-2 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
                  </svg>
                  <span className="text-text-secondary text-lg block font-semibold">
                    {product.brand || "Product"}
                  </span>
                  <span className="text-text-secondary text-sm">
                    Image Not Available
                  </span>
                </div>
              </div>
            )}
          </div>

          {/* Thumbnail Gallery - Show different color variants */}
          {variantImages.length > 1 && (
            <div className="flex gap-2 overflow-x-auto pb-2">
              {variantImages.map((img, index) => (
                <button
                  key={index}
                  onClick={() => {
                    setCurrentImageIndex(index);
                    // Also switch to the matching variant
                    const matchingVariant = product.variants.find(
                      v => v.color === img.color
                    );
                    if (matchingVariant) {
                      handleVariantChange(matchingVariant.variant_id);
                    }
                  }}
                  className={`relative flex-shrink-0 w-20 h-20 rounded-lg overflow-hidden border-2 transition-all ${
                    index === currentImageIndex
                      ? "border-secondary shadow-lg scale-105"
                      : "border-card-border hover:border-primary"
                  }`}
                >
                  <img
                    src={img.url}
                    alt={`${product.name} - ${img.color || 'variant'}`}
                    className="w-full h-full object-cover"
                    onError={(e) => {
                      e.target.onerror = null;
                      e.target.src = "";
                    }}
                  />
                  {img.color && (
                    <div className="absolute bottom-0 left-0 right-0 bg-black/70 text-white text-xs py-0.5 px-1 text-center truncate">
                      {img.color}
                    </div>
                  )}
                  {index === currentImageIndex && (
                    <div className="absolute inset-0 border-2 border-secondary rounded-lg pointer-events-none"></div>
                  )}
                </button>
              ))}
            </div>
          )}
        </div>

        {/* Product Details */}
        <div>
          <h1 className="text-3xl font-bold text-text-primary mb-2">
            {product.name}
          </h1>
          {product.brand && (
            <p className="text-lg text-text-secondary mb-4">
              by <span className="font-semibold">{product.brand}</span>
            </p>
          )}
          <div className="flex items-center mb-4 gap-2">
            <span
              className={`inline-flex items-center gap-2 px-3 py-1 rounded-full text-sm font-semibold ${
                isInStock 
                  ? "bg-green-100 text-green-700 border border-green-300" 
                  : "bg-orange-100 text-orange-700 border border-orange-300"
              }`}
            >
              {isInStock ? (
                <>
                  <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                    <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd"/>
                  </svg>
                  In Stock - Ships Immediately
                </>
              ) : (
                <>
                  <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                    <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm1-12a1 1 0 10-2 0v4a1 1 0 00.293.707l2.828 2.829a1 1 0 101.415-1.415L11 9.586V6z" clipRule="evenodd"/>
                  </svg>
                  Available for Backorder
                </>
              )}
            </span>
          </div>
          {selectedVariant?.description && (
            <div className="text-text-secondary mb-6">
              <p>{selectedVariant.description}</p>
            </div>
          )}

          {/* Variant Selection Section */}
          {product.variants && product.variants.length > 1 && (
            <div className="mb-6 p-4 bg-card border border-card-border rounded-lg">
              <h3 className="text-lg font-semibold text-text-primary mb-4">
                Choose Your Variant
              </h3>

              {/* Color Selection */}
              {getUniqueAttributes("color").length > 0 && (
                <div className="mb-4">
                  <label className="text-md font-semibold text-text-primary mb-3 block">
                    Color:{" "}
                    <span className="font-normal text-text-secondary">
                      {selectedVariant?.color}
                    </span>
                  </label>
                  <div className="flex gap-3 flex-wrap">
                    {getUniqueAttributes("color").map((color) => {
                      const isAvailable = product.variants.some(
                        (v) => v.color === color && v.stock_quantity > 0
                      );
                      const isSelected = selectedVariant?.color === color;
                      
                      // Get image for this color variant
                      const colorVariant = product.variants.find(v => v.color === color);
                      const colorImageUrl = colorVariant ? getImageUrl(colorVariant.image_url) : null;

                      return (
                        <button
                          key={color}
                          onClick={() =>
                            handleVariantChange(
                              findMatchingVariant("color", color)
                            )
                          }
                          className={`group relative flex items-center gap-2 px-3 py-2 rounded-lg border-2 transition-all ${
                            isSelected
                              ? "border-secondary bg-secondary text-white shadow-lg scale-105"
                              : isAvailable
                              ? "border-card-border bg-card text-text-primary hover:border-primary hover:shadow-md"
                              : "border-orange-300 bg-orange-50 text-orange-700 hover:border-orange-400"
                          }`}
                        >
                          {/* Small preview image */}
                          {colorImageUrl && (
                            <div className={`w-10 h-10 rounded overflow-hidden flex-shrink-0 border ${
                              isSelected ? 'border-white' : 'border-gray-300'
                            }`}>
                              <img
                                src={colorImageUrl}
                                alt={color}
                                className="w-full h-full object-cover"
                                onError={(e) => {
                                  e.target.style.display = 'none';
                                }}
                              />
                            </div>
                          )}
                          
                          <div className="flex flex-col items-start">
                            <span className="text-sm font-semibold">{color}</span>
                            {!isAvailable && (
                              <span className="text-xs opacity-80">(Backorder)</span>
                            )}
                          </div>
                          
                          {/* Checkmark for selected */}
                          {isSelected && (
                            <svg className="w-4 h-4 ml-1 flex-shrink-0" fill="currentColor" viewBox="0 0 20 20">
                              <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd"/>
                            </svg>
                          )}
                        </button>
                      );
                    })}
                  </div>
                </div>
              )}

              {/* Size Selection */}
              {getUniqueAttributes("size").length > 0 && (
                <div className="mb-4">
                  <label className="text-md font-semibold text-text-primary mb-2 block">
                    Size:{" "}
                    <span className="font-normal text-text-secondary">
                      {selectedVariant?.size}
                    </span>
                  </label>
                  <div className="flex gap-2 flex-wrap">
                    {getUniqueAttributes("size").map((size) => {
                      const isAvailable = product.variants.some(
                        (v) => v.size === size && v.stock_quantity > 0
                      );
                      const isSelected = selectedVariant?.size === size;

                      return (
                        <button
                          key={size}
                          onClick={() =>
                            handleVariantChange(
                              findMatchingVariant("size", size)
                            )
                          }
                          className={`px-4 py-2 rounded-md text-sm font-semibold border-2 transition-all ${
                            isSelected
                              ? "border-secondary bg-secondary text-white shadow-md"
                              : isAvailable
                              ? "border-card-border bg-card text-text-primary hover:border-primary"
                              : "border-orange-300 bg-orange-50 text-orange-700 hover:border-orange-400"
                          }`}
                        >
                          {size}
                          {!isAvailable && (
                            <span className="ml-1 text-xs">(Backorder)</span>
                          )}
                        </button>
                      );
                    })}
                  </div>
                </div>
              )}

              {/* Selected Variant Info */}
              <div className="mt-4 pt-4 border-t border-card-border">
                <div className="flex items-center justify-between text-sm">
                  <span className="text-text-secondary">
                    SKU:{" "}
                    <span className="font-mono">{selectedVariant?.sku}</span>
                  </span>
                  <span
                    className={`inline-flex items-center gap-1 px-2 py-1 rounded-full text-xs font-semibold ${
                      selectedVariant?.stock_quantity > 0
                        ? "bg-green-100 text-green-700 border border-green-300"
                        : "bg-orange-100 text-orange-700 border border-orange-300"
                    }`}
                  >
                    {selectedVariant?.stock_quantity > 0 ? (
                      <>
                        <svg className="w-3 h-3" fill="currentColor" viewBox="0 0 20 20">
                          <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd"/>
                        </svg>
                        In Stock
                      </>
                    ) : (
                      <>
                        <svg className="w-3 h-3" fill="currentColor" viewBox="0 0 20 20">
                          <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm1-12a1 1 0 10-2 0v4a1 1 0 00.293.707l2.828 2.829a1 1 0 101.415-1.415L11 9.586V6z" clipRule="evenodd"/>
                        </svg>
                        Backorder
                      </>
                    )}
                  </span>
                </div>
              </div>
            </div>
          )}

          {/* Single Variant Info */}
          {product.variants && product.variants.length === 1 && (
            <div className="mb-4 p-3 bg-blue-50 border border-blue-200 rounded-md">
              <p className="text-sm text-blue-800">
                <i className="fas fa-info-circle mr-2"></i>
                This product has only one variant available
              </p>
            </div>
          )}

          <div className="mb-6">
            <span className="text-4xl font-extrabold text-primary">
              ${" "}
              {selectedVariant?.price
                ? parseFloat(selectedVariant.price).toFixed(2)
                : "N/A"}
            </span>
          </div>

          {/* Delivery Information */}
          <div className={`mb-6 p-4 rounded-lg border ${
            isInStock 
              ? "bg-blue-50 dark:bg-blue-900/20 border-blue-200 dark:border-blue-800" 
              : "bg-orange-50 dark:bg-orange-900/20 border-orange-200 dark:border-orange-800"
          }`}>
            <div className="flex items-start gap-3">
              <svg className={`w-6 h-6 mt-0.5 flex-shrink-0 ${
                isInStock 
                  ? "text-blue-600 dark:text-blue-400" 
                  : "text-orange-600 dark:text-orange-400"
              }`} fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 8h14M5 8a2 2 0 110-4h14a2 2 0 110 4M5 8v10a2 2 0 002 2h10a2 2 0 002-2V8m-9 4h4" />
              </svg>
              <div>
                <p className={`font-semibold mb-1 ${
                  isInStock 
                    ? "text-blue-800 dark:text-blue-300" 
                    : "text-orange-800 dark:text-orange-300"
                }`}>
                  {isInStock ? "Estimated Delivery" : "Backorder - Estimated Delivery"}
                </p>
                <p className={`text-sm ${
                  isInStock 
                    ? "text-blue-700 dark:text-blue-400" 
                    : "text-orange-700 dark:text-orange-400"
                }`}>
                  {estimatedDelivery}
                </p>
                {!isInStock && (
                  <div className="mt-2 p-2 bg-white/50 dark:bg-black/20 rounded border border-orange-300 dark:border-orange-700">
                    <p className="text-xs text-orange-800 dark:text-orange-300 font-semibold mb-1">
                      📦 How Backorders Work:
                    </p>
                    <ul className="text-xs text-orange-700 dark:text-orange-400 space-y-0.5">
                      <li>• You can order now and we'll ship when restocked</li>
                      <li>• Additional 3 days added to standard delivery time</li>
                      <li>• Payment processed at checkout as normal</li>
                      <li>• You'll be notified when your order ships</li>
                    </ul>
                  </div>
                )}
              </div>
            </div>
          </div>

          {/* Quantity Selector - Only show for customers, not staff */}
          {userRole !== "staff" && (
            <div className="mb-6">
              <label className="text-md font-semibold text-text-primary mb-2 block">
                Quantity
              </label>
              <div className="flex items-center gap-4">
                <div className="flex items-center border-2 border-card-border rounded-lg overflow-hidden">
                  <button
                    onClick={decrementQuantity}
                    disabled={quantity <= 1}
                    className="px-4 py-2 bg-card hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M20 12H4" />
                    </svg>
                  </button>
                  <input
                    type="number"
                    min="1"
                    value={quantity}
                    onChange={handleQuantityInput}
                    className="w-20 text-center py-2 border-x-2 border-card-border bg-background text-text-primary font-semibold focus:outline-none"
                  />
                  <button
                    onClick={incrementQuantity}
                    className="px-4 py-2 bg-card hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors"
                  >
                    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
                    </svg>
                  </button>
                </div>
                <span className="text-sm text-text-secondary">
                  {isInStock ? "In Stock" : "Backorder Available"}
                </span>
              </div>
            </div>
          )}

          {/* Action Buttons - Hide for staff */}
          {userRole !== "staff" && (
            <div className="flex flex-col gap-4">
              <div className="flex items-center gap-4">
                <button
                  onClick={handleAddToCart}
                  className={`w-full py-3 rounded-lg font-semibold text-lg transition ${
                    isInStock 
                      ? "bg-secondary text-white hover:opacity-90" 
                      : "bg-orange-500 text-white hover:bg-orange-600"
                  }`}
                >
                  <i className="fas fa-shopping-cart mr-2"></i> 
                  {isInStock ? "Add to Cart" : "Add to Cart (Backorder)"}
                </button>
                <button
                  onClick={handleBuyNow}
                  className={`w-full py-3 rounded-lg font-semibold text-lg transition ${
                    isInStock 
                      ? "bg-primary text-white hover:bg-secondary" 
                      : "bg-orange-600 text-white hover:bg-orange-700"
                  }`}
                >
                  {isInStock ? "Buy Now" : "Backorder Now"}
                </button>
              </div>

              {!isInStock && (
                <div className="p-3 bg-orange-50 dark:bg-orange-900/20 border border-orange-300 dark:border-orange-700 rounded-md">
                  <p className="text-sm text-orange-800 dark:text-orange-300 text-center">
                    <svg className="w-5 h-5 inline mr-1" fill="currentColor" viewBox="0 0 20 20">
                      <path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clipRule="evenodd"/>
                    </svg>
                    <strong>Item will ship when restocked.</strong> We'll process your payment now and send updates via email.
                  </p>
                </div>
              )}

              {addedToCart && (
                <div className="p-3 bg-green-100 border border-green-300 text-green-800 rounded-md text-center">
                  <svg className="w-5 h-5 inline mr-1" fill="currentColor" viewBox="0 0 20 20">
                    <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd"/>
                  </svg>
                  Successfully added {quantity} {quantity === 1 ? "item" : "items"} to cart!
                  {!isInStock && " (Backorder)"}
                </div>
              )}
            </div>
          )}

          {/* Staff view - no action buttons */}
          {userRole === "staff" && (
            <div className="p-4 bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-800 rounded-lg">
              <p className="text-yellow-800 dark:text-yellow-300 text-sm">
                <svg className="w-5 h-5 inline mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
                You are viewing this as staff. Purchase functionality is disabled.
              </p>
            </div>
          )}
        </div>
      </div>
      {/* Similar Products section can be added here if needed */}
    </div>
  );
}
